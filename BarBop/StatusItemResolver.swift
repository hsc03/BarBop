//
//  StatusItemResolver.swift
//  BarBop
//
//  Created by Codex on 7/11/26.
//

import AppKit
import ApplicationServices

struct StatusItemResolution: Equatable {
    let role: String?
    let title: String?
    let accessibilityIdentifier: String?
    let processIdentifier: pid_t?
    let bundleIdentifier: String?
    let applicationName: String?
    let identity: String
    let errorDescription: String?
}

struct StatusItemIdentityInput: Equatable {
    let bundleIdentifier: String?
    let accessibilityIdentifier: String?
    let title: String?
    let processIdentifier: pid_t?
}

enum StatusItemIdentity {
    static let unknown = "status-item:unknown"

    static func makeID(from input: StatusItemIdentityInput) -> String {
        let bundleIdentifier = normalized(input.bundleIdentifier)
        let accessibilityIdentifier = normalized(input.accessibilityIdentifier)
        let title = normalized(input.title)

        if let bundleIdentifier, let accessibilityIdentifier {
            return "bundle:\(bundleIdentifier)|axid:\(accessibilityIdentifier)"
        }

        if let bundleIdentifier, let title {
            return "bundle:\(bundleIdentifier)|title:\(title)"
        }

        if let bundleIdentifier, isSystemStatusItemBundle(bundleIdentifier), let processIdentifier = input.processIdentifier {
            return "system:\(bundleIdentifier)|pid:\(processIdentifier)"
        }

        if let bundleIdentifier {
            return "bundle:\(bundleIdentifier)"
        }

        return unknown
    }

    private static func normalized(_ value: String?) -> String? {
        guard let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else {
            return nil
        }

        return trimmed
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "|", with: "/")
    }

    private static func isSystemStatusItemBundle(_ bundleIdentifier: String) -> Bool {
        bundleIdentifier == "com.apple.systemuiserver" || bundleIdentifier == "com.apple.controlcenter"
    }
}

final class StatusItemResolver {
    private let maximumParentTraversalDepth = 8

    func resolve(at location: CGPoint) -> StatusItemResolution {
        guard AXIsProcessTrusted() else {
            return fallback(errorDescription: "Accessibility permission is not trusted")
        }

        let systemWideElement = AXUIElementCreateSystemWide()
        var hitElement: AXUIElement?
        let hitError = AXUIElementCopyElementAtPosition(
            systemWideElement,
            Float(location.x),
            Float(location.y),
            &hitElement
        )

        guard hitError == .success, let hitElement else {
            return fallback(errorDescription: "Accessibility hit test failed: \(hitError)")
        }

        let candidate = bestCandidate(startingAt: hitElement)
        let processIdentifier = processIdentifier(for: candidate) ?? processIdentifier(for: hitElement)
        let runningApplication = processIdentifier.flatMap { NSRunningApplication(processIdentifier: $0) }
        let role = stringAttribute(kAXRoleAttribute, from: candidate)
        let title = firstStringAttribute([kAXTitleAttribute, kAXDescriptionAttribute], from: candidate)
        let accessibilityIdentifier = stringAttribute(kAXIdentifierAttribute, from: candidate)
        let bundleIdentifier = runningApplication?.bundleIdentifier
        let applicationName = runningApplication?.localizedName
        let identity = StatusItemIdentity.makeID(
            from: StatusItemIdentityInput(
                bundleIdentifier: bundleIdentifier,
                accessibilityIdentifier: accessibilityIdentifier,
                title: title,
                processIdentifier: processIdentifier
            )
        )

        return StatusItemResolution(
            role: role,
            title: title,
            accessibilityIdentifier: accessibilityIdentifier,
            processIdentifier: processIdentifier,
            bundleIdentifier: bundleIdentifier,
            applicationName: applicationName,
            identity: identity,
            errorDescription: nil
        )
    }

    private func bestCandidate(startingAt element: AXUIElement) -> AXUIElement {
        var current = element
        var best = element

        for _ in 0..<maximumParentTraversalDepth {
            if isStatusItemLike(current) {
                return current
            }

            if hasUsefulIdentity(current) {
                best = current
            }

            guard let parent = parent(of: current) else {
                break
            }

            current = parent
        }

        return best
    }

    private func isStatusItemLike(_ element: AXUIElement) -> Bool {
        guard let role = stringAttribute(kAXRoleAttribute, from: element) else {
            return false
        }

        return role == kAXMenuBarItemRole
            || role == kAXMenuItemRole
            || role == kAXMenuRole
            || role.localizedCaseInsensitiveContains("menu")
    }

    private func hasUsefulIdentity(_ element: AXUIElement) -> Bool {
        stringAttribute(kAXIdentifierAttribute, from: element) != nil
            || stringAttribute(kAXTitleAttribute, from: element) != nil
            || stringAttribute(kAXDescriptionAttribute, from: element) != nil
    }

    private func parent(of element: AXUIElement) -> AXUIElement? {
        var value: CFTypeRef?
        let error = AXUIElementCopyAttributeValue(element, kAXParentAttribute as CFString, &value)

        guard error == .success else {
            return nil
        }

        guard let value, CFGetTypeID(value) == AXUIElementGetTypeID() else {
            return nil
        }

        return (value as! AXUIElement)
    }

    private func processIdentifier(for element: AXUIElement) -> pid_t? {
        var processIdentifier = pid_t()
        let error = AXUIElementGetPid(element, &processIdentifier)

        guard error == .success else {
            return nil
        }

        return processIdentifier
    }

    private func firstStringAttribute(_ attributes: [String], from element: AXUIElement) -> String? {
        for attribute in attributes {
            if let value = stringAttribute(attribute, from: element) {
                return value
            }
        }

        return nil
    }

    private func stringAttribute(_ attribute: String, from element: AXUIElement) -> String? {
        var value: CFTypeRef?
        let error = AXUIElementCopyAttributeValue(element, attribute as CFString, &value)

        guard error == .success else {
            return nil
        }

        return value as? String
    }

    private func fallback(errorDescription: String) -> StatusItemResolution {
        StatusItemResolution(
            role: nil,
            title: nil,
            accessibilityIdentifier: nil,
            processIdentifier: nil,
            bundleIdentifier: nil,
            applicationName: nil,
            identity: StatusItemIdentity.unknown,
            errorDescription: errorDescription
        )
    }
}
