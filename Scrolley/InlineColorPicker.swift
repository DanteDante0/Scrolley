import AppKit
import SwiftUI

struct InlineColorPicker: View {
    let title: String
    @Binding var color: Color
    var disabled: Bool = false

    @State private var expanded = false
    @State private var markerFraction: CGPoint?

    private let wheelSize: CGFloat = 150

    private static let presets: [Color] = [
        Color(.sRGB, red: 1.00, green: 1.00, blue: 1.00, opacity: 1),
        Color(.sRGB, red: 0.80, green: 0.80, blue: 0.82, opacity: 1),
        Color(.sRGB, red: 0.50, green: 0.50, blue: 0.53, opacity: 1),
        Color(.sRGB, red: 0.20, green: 0.20, blue: 0.22, opacity: 1),
        Color(.sRGB, red: 0.00, green: 0.00, blue: 0.00, opacity: 1),
        Color(.sRGB, red: 0.96, green: 0.26, blue: 0.21, opacity: 1),
        Color(.sRGB, red: 1.00, green: 0.58, blue: 0.00, opacity: 1),
        Color(.sRGB, red: 1.00, green: 0.84, blue: 0.00, opacity: 1),
        Color(.sRGB, red: 0.30, green: 0.69, blue: 0.31, opacity: 1),
        Color(.sRGB, red: 0.00, green: 0.74, blue: 0.83, opacity: 1),
        Color(.sRGB, red: 0.13, green: 0.59, blue: 0.95, opacity: 1),
        Color(.sRGB, red: 0.40, green: 0.23, blue: 0.72, opacity: 1),
        Color(.sRGB, red: 0.61, green: 0.15, blue: 0.69, opacity: 1),
        Color(.sRGB, red: 0.91, green: 0.12, blue: 0.39, opacity: 1),
    ]

    var body: some View {
        DisclosureGroup(isExpanded: $expanded) {
            VStack(alignment: .leading, spacing: 10) {
                presetRow
                wheel
                opacityRow
                Button {
                    sampleFromScreen()
                } label: {
                    Label("Pick from screen", systemImage: "eyedropper")
                        .font(.system(size: 14))
                }
                .controlSize(.small)
            }
            .padding(.top, 6)
        } label: {
            HStack {
                Text(title).font(.system(size: 15))
                Spacer()
                swatch
            }
        }
        .opacity(disabled ? 0.4 : 1.0)
        .disabled(disabled)
    }

    private var swatch: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(color)
            .frame(width: 32, height: 16)
            .background(Checkerboard().clipShape(RoundedRectangle(cornerRadius: 4)))
            .overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(Color.primary.opacity(0.3)))
    }

    private var presetRow: some View {
        HStack(spacing: 4) {
            ForEach(Self.presets.indices, id: \.self) { index in
                let preset = Self.presets[index]
                Circle()
                    .fill(preset)
                    .frame(width: 16, height: 16)
                    .overlay(Circle().strokeBorder(Color.primary.opacity(0.25), lineWidth: 1))
                    .overlay(Circle().strokeBorder(Color.accentColor, lineWidth: isSelected(preset) ? 2 : 0))
                    .contentShape(Circle())
                    .onTapGesture {
                        setRGB(preset)
                        markerFraction = nil
                    }
            }
        }
    }

    private var wheel: some View {
        Image("ColorWheel")
            .resizable()
            .interpolation(.high)
            .scaledToFit()
            .frame(width: wheelSize, height: wheelSize)
            .overlay(markerOverlay)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .local)
                    .onChanged { value in pick(at: value.location) }
            )
            .frame(maxWidth: .infinity, alignment: .center)
    }

    private var markerOverlay: some View {
        GeometryReader { geo in
            if let fraction = markerFraction {
                Circle()
                    .stroke(Color.black.opacity(0.7), lineWidth: 3)
                    .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
                    .frame(width: 14, height: 14)
                    .position(x: fraction.x * geo.size.width, y: fraction.y * geo.size.height)
                    .allowsHitTesting(false)
            }
        }
    }

    private var opacityRow: some View {
        HStack(spacing: 8) {
            Image(systemName: "circle.lefthalf.filled").font(.system(size: 14)).foregroundStyle(.secondary)
            Slider(value: opacityBinding, in: 0...1)
            Text("\(Int(Self.alpha(color) * 100))%")
                .font(.system(size: 14).monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 34, alignment: .trailing)
        }
    }

    private func pick(at location: CGPoint) {
        let fx = min(max(location.x / wheelSize, 0), 1)
        let fy = min(max(location.y / wheelSize, 0), 1)
        guard let sampled = ColorWheelImage.color(atFraction: CGPoint(x: fx, y: fy)) else { return }
        setRGB(sampled)
        markerFraction = CGPoint(x: fx, y: fy)
    }

    private func sampleFromScreen() {
        NSColorSampler().show { picked in
            guard let picked, let srgb = picked.usingColorSpace(.sRGB) else { return }
            setRGB(Color(.sRGB,
                         red: Double(srgb.redComponent),
                         green: Double(srgb.greenComponent),
                         blue: Double(srgb.blueComponent),
                         opacity: 1))
            markerFraction = nil
        }
    }

    private func setRGB(_ newColor: Color) {
        let rgb = Self.rgb(newColor)
        color = Color(.sRGB, red: rgb.0, green: rgb.1, blue: rgb.2, opacity: Self.alpha(color))
    }

    private var opacityBinding: Binding<Double> {
        Binding(
            get: { Self.alpha(color) },
            set: { newValue in
                let rgb = Self.rgb(color)
                color = Color(.sRGB, red: rgb.0, green: rgb.1, blue: rgb.2, opacity: newValue)
            }
        )
    }

    private func isSelected(_ candidate: Color) -> Bool {
        let a = Self.rgb(candidate)
        let b = Self.rgb(color)
        return abs(a.0 - b.0) < 0.02 && abs(a.1 - b.1) < 0.02 && abs(a.2 - b.2) < 0.02
    }

    private static func rgb(_ color: Color) -> (Double, Double, Double) {
        let ns = NSColor(color).usingColorSpace(.sRGB) ?? NSColor(color)
        return (Double(ns.redComponent), Double(ns.greenComponent), Double(ns.blueComponent))
    }

    private static func alpha(_ color: Color) -> Double {
        let ns = NSColor(color).usingColorSpace(.sRGB) ?? NSColor(color)
        return Double(ns.alphaComponent)
    }
}

struct Checkerboard: View {
    var body: some View {
        Canvas { context, size in
            let tile: CGFloat = 4
            var y: CGFloat = 0
            while y < size.height {
                var x: CGFloat = 0
                while x < size.width {
                    let dark = (Int(x / tile) + Int(y / tile)) % 2 == 0
                    context.fill(
                        Path(CGRect(x: x, y: y, width: tile, height: tile)),
                        with: .color(dark ? Color(white: 0.75) : Color(white: 0.95))
                    )
                    x += tile
                }
                y += tile
            }
        }
    }
}
