import SwiftUI

struct MenuContent: View {
    @EnvironmentObject private var state: AppState
    @EnvironmentObject private var permissions: PermissionsManager
    let coordinator: AppDelegate
    @State private var appearanceExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                header
                previewStrip
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if !permissions.accessibilityGranted {
                        permissionBanner
                    }
                    Divider()
                    sliders
                    Divider()
                    toggles
                    Divider()
                    appearance
                    Divider()
                    exclusions
                    Divider()
                    footer
                }
                .padding(14)
                .frame(width: 320)
            }
        }
        .font(.system(size: 15))
        .frame(width: 320, height: 560)
    }

    private var header: some View {
        HStack {
            Image(systemName: "arrow.up.and.down.and.arrow.left.and.right")
                .foregroundStyle(.tint)
            Text("Scrolley").font(.system(size: 15, weight: .semibold))
            Spacer()
            Toggle("", isOn: $state.enabled)
                .labelsHidden()
                .toggleStyle(.switch)
        }
    }

    private var previewStrip: some View {
        HStack(spacing: 10) {
            Text("Overlay preview").font(.system(size: 14)).foregroundStyle(.secondary)
            Spacer()
            OverlayIcon(style: previewStyle, size: CGFloat(state.overlaySize))
                .opacity(state.overlayOpacity)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity)
        .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 8))
        .opacity(state.showOverlay ? 1.0 : 0.4)
    }

    private var permissionBanner: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Accessibility permission required", systemImage: "exclamationmark.triangle.fill")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.orange)
            Text("Scrolley needs Accessibility access to read the middle button and post scroll events.")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
            Button("Grant Accessibility…") { permissions.promptAccessibility() }
            if !permissions.inputMonitoringGranted {
                Button("Open Input Monitoring…") { permissions.openInputMonitoringSettings() }
                    .font(.system(size: 14))
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
    }

    private var sliders: some View {
        VStack(alignment: .leading, spacing: 10) {
            slider("Vertical sensitivity",
                   value: $state.verticalSensitivity, range: 0.2...10.0,
                   readout: String(format: "%.1f×", state.verticalSensitivity))
            slider("Horizontal sensitivity",
                   value: $state.horizontalSensitivity, range: 0.2...10.0,
                   readout: String(format: "%.1f×", state.horizontalSensitivity))
            slider("Smoothness",
                   value: $state.smoothness, range: 0.0...1.0,
                   readout: "\(Int(state.smoothness * 100))%")
            slider("Middle-click hold time",
                   value: $state.holdActivationMs, range: 1...500,
                   readout: "\(Int(state.holdActivationMs)) ms")
        }
    }

    private func slider(_ title: String, value: Binding<Double>, range: ClosedRange<Double>, readout: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(title).font(.system(size: 15))
                Spacer()
                Text(readout).font(.system(size: 14)).foregroundStyle(.secondary)
            }
            Slider(value: value, in: range)
        }
    }

    private var toggles: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle("Show overlay icon", isOn: $state.showOverlay)
            slider("Overlay opacity",
                   value: $state.overlayOpacity, range: 0.05...1.0,
                   readout: "\(Int(state.overlayOpacity * 100))%")
                .disabled(!state.showOverlay)
                .opacity(state.showOverlay ? 1.0 : 0.4)
            slider("Overlay size",
                   value: $state.overlaySize, range: 36...144,
                   readout: "\(Int(state.overlaySize)) pt")
                .disabled(!state.showOverlay)
                .opacity(state.showOverlay ? 1.0 : 0.4)
            Toggle("Natural scroll direction", isOn: $state.naturalDirection)
            Toggle("Launch at login", isOn: $state.launchAtLogin)
        }
        .toggleStyle(.switch)
    }

    private var appearance: some View {
        DisclosureGroup(isExpanded: $appearanceExpanded) {
            VStack(alignment: .leading, spacing: 10) {
                shapeSelector
                Toggle("Frosted background", isOn: $state.frostedBackground)
                    .toggleStyle(.switch)
                InlineColorPicker(title: "Background color", color: $state.overlayBackgroundColor)
                InlineColorPicker(title: "Cursor color", color: $state.cursorColor)
                Toggle("Ring matches cursor color", isOn: $state.ringMatchesCursor)
                    .toggleStyle(.switch)
                InlineColorPicker(title: "Ring color", color: $state.ringColor, disabled: state.ringMatchesCursor)
            }
            .padding(.top, 8)
        } label: {
            Text("Overlay appearance").font(.system(size: 15))
        }
        .disabled(!state.showOverlay)
        .opacity(state.showOverlay ? 1.0 : 0.4)
    }

    private var shapeSelector: some View {
        HStack(spacing: 8) {
            ForEach(OverlayShape.allCases, id: \.self) { shape in
                Button {
                    state.overlayShape = shape
                } label: {
                    shapeThumbnail(shape)
                        .frame(width: 24, height: 24)
                        .padding(5)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(state.overlayShape == shape ? Color.accentColor.opacity(0.3) : Color.primary.opacity(0.06))
                        )
                }
                .buttonStyle(.plain)
                .help(shape.displayName)
            }
        }
    }

    @ViewBuilder
    private func shapeThumbnail(_ shape: OverlayShape) -> some View {
        if shape == .none {
            Image(systemName: "nosign")
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(Color.primary.opacity(0.8))
        } else {
            shape.anyShape.stroke(Color.primary.opacity(0.8), lineWidth: 1.5)
        }
    }

    private var previewStyle: OverlayStyle {
        let ring = state.ringMatchesCursor
            ? AppState.rgba(from: state.cursorColor)
            : AppState.rgba(from: state.ringColor)
        return OverlayStyle(
            shape: state.overlayShape,
            frosted: state.frostedBackground,
            cursor: AppState.rgba(from: state.cursorColor),
            background: AppState.rgba(from: state.overlayBackgroundColor),
            ring: ring
        )
    }

    private var exclusions: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Excluded apps").font(.system(size: 15))
                Spacer()
                Button("Add frontmost app") { coordinator.addExcludedFrontmostApp() }
                    .font(.system(size: 14))
            }
            if state.excludedApps.isEmpty {
                Text("None").font(.system(size: 14)).foregroundStyle(.secondary)
            } else {
                ForEach(state.excludedApps, id: \.self) { bundle in
                    HStack {
                        Text(bundle).font(.system(size: 14)).lineLimit(1).truncationMode(.middle)
                        Spacer()
                        Button {
                            state.removeExcluded(bundle)
                        } label: {
                            Image(systemName: "minus.circle.fill").foregroundStyle(.red)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var footer: some View {
        HStack {
            Button {
                coordinator.openSupport()
            } label: {
                Label("Buy me tea?", systemImage: "cup.and.saucer.fill")
            }
            Spacer()
            Button("Quit Scrolley") { coordinator.quit() }
        }
    }
}
