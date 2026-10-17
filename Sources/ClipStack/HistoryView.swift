import SwiftUI
import AppKit

// MARK: - Caches

@MainActor
enum ImageCache {
    private static let thumbs = NSCache<NSString, NSImage>()
    private static var icons: [String: NSImage] = [:]

    static func thumbnail(file: String) -> NSImage? {
        if let c = thumbs.object(forKey: file as NSString) { return c }
        let url = ClipboardStore.shared.imagesURL.appendingPathComponent(file)
        guard let src = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
        let opts: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: 320,
        ]
        guard let cg = CGImageSourceCreateThumbnailAtIndex(src, 0, opts as CFDictionary) else { return nil }
        let img = NSImage(cgImage: cg, size: NSSize(width: cg.width, height: cg.height))
        thumbs.setObject(img, forKey: file as NSString)
        return img
    }

    static func appIcon(bundleID: String?) -> NSImage? {
        guard let id = bundleID else { return nil }
        if let c = icons[id] { return c }
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: id) else { return nil }
        let img = NSWorkspace.shared.icon(forFile: url.path)
        icons[id] = img
        return img
    }
}

// MARK: - Theme

enum Theme {
    static let accent = Color(red: 0.56, green: 0.38, blue: 0.99)
    static let accentDeep = Color(red: 0.40, green: 0.26, blue: 0.92)
    static let glass = Color.white.opacity(0.06)
    static let glassBorder = Color.white.opacity(0.10)
    static let textSecondary = Color.white.opacity(0.55)
    static let tile = LinearGradient(colors: [Color(red: 0.62, green: 0.45, blue: 1.0), Color(red: 0.42, green: 0.28, blue: 0.93)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing)
}

private func parseHexColor(_ raw: String?) -> Color? {
    guard var t = raw?.trimmingCharacters(in: .whitespacesAndNewlines), t.hasPrefix("#") else { return nil }
    t.removeFirst()
    guard [3, 6, 8].contains(t.count), t.allSatisfy(\.isHexDigit) else { return nil }
    if t.count == 3 { t = t.map { "\($0)\($0)" }.joined() }
    var v: UInt64 = 0
    Scanner(string: String(t.prefix(6))).scanHexInt64(&v)
    return Color(red: Double((v >> 16) & 0xFF) / 255, green: Double((v >> 8) & 0xFF) / 255, blue: Double(v & 0xFF) / 255)
}

extension ClipItem {
    /// One short line: the first non-empty line of text, links without the scheme.
    var title: String {
        switch kind {
        case .image: return "Image" + (imageSize.map { " \($0)" } ?? "")
        case .text:
            let line = (text ?? "").split(whereSeparator: \.isNewline)
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .first(where: { !$0.isEmpty }) ?? ""
            let t = isLink ? line.replacingOccurrences(of: #"^https?://(www\.)?"#, with: "", options: .regularExpression) : line
            return String(t.prefix(120))
        }
    }
}

// MARK: - Main view

struct HistoryView: View {
    @ObservedObject var model: PanelModel
    @FocusState private var searchFocused: Bool

    var body: some View {
        let items = model.visible
        VStack(spacing: 0) {
            header
            if items.isEmpty {
                emptyState
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        if model.filter == .images {
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                                    ImageTile(
                                        item: item,
                                        index: index,
                                        selected: item.id == model.selectedID,
                                        onPaste: { model.onActivate?(item) },
                                        onPin: { model.store.togglePin(item.id) },
                                        onDelete: { model.store.delete(item.id) }
                                    )
                                    .id(item.id)
                                    .onHover { inside in if inside { model.selectedID = item.id } }
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                        } else {
                            LazyVStack(spacing: 6) {
                                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                                    ClipRow(
                                        item: item,
                                        index: index,
                                        selected: item.id == model.selectedID,
                                        onPaste: { model.onActivate?(item) },
                                        onPin: { model.store.togglePin(item.id) },
                                        onDelete: { model.store.delete(item.id) }
                                    )
                                    .id(item.id)
                                    .onHover { inside in if inside { model.selectedID = item.id } }
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                        }
                    }
                    .onChange(of: model.selectedID) { _, id in
                        guard let id else { return }
                        withAnimation(.easeOut(duration: 0.1)) { proxy.scrollTo(id) }
                    }
                }
            }
            footer
        }
        .background(
            ZStack {
                LinearGradient(colors: [Color(red: 0.16, green: 0.09, blue: 0.40).opacity(0.78), Color(red: 0.07, green: 0.05, blue: 0.20).opacity(0.85)],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
                RadialGradient(colors: [Theme.accent.opacity(0.35), .clear], center: .topTrailing, startRadius: 0, endRadius: 360)
            }
        )
        .environment(\.colorScheme, .dark)
        .onAppear { searchFocused = true }
        .onChange(of: model.focusTick) { _, _ in searchFocused = true }
    }

    private var header: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass").font(.system(size: 14, weight: .medium)).foregroundStyle(Theme.textSecondary)
                TextField("Search clipboard history", text: $model.query)
                    .textFieldStyle(.plain)
                    .font(.system(size: 15))
                    .focused($searchFocused)
                if !model.query.isEmpty {
                    Button { model.query = "" } label: {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(Theme.textSecondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.glass))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Theme.glassBorder, lineWidth: 1))

            HStack(spacing: 8) {
                ForEach(ClipFilter.allCases) { f in
                    let on = model.filter == f
                    Button { model.filter = f } label: {
                        Text(f.rawValue)
                            .font(.system(size: 12, weight: .semibold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(on ? AnyShapeStyle(Theme.tile) : AnyShapeStyle(Theme.glass)))
                            .overlay(Capsule().stroke(on ? Color.white.opacity(0.25) : Theme.glassBorder, lineWidth: 1))
                            .foregroundStyle(on ? Color.white : Color.white.opacity(0.7))
                            .shadow(color: on ? Theme.accent.opacity(0.5) : .clear, radius: 8)
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 16)
        .padding(.bottom, 10)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Spacer()
            Image(systemName: model.query.isEmpty ? "doc.on.clipboard" : "magnifyingglass")
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(Theme.accent)
            Text(model.query.isEmpty ? "Nothing here yet" : "No results")
                .font(.system(size: 15, weight: .semibold))
            Text(model.query.isEmpty ? "Copy something and it will show up here." : "Try a different search or filter.")
                .font(.system(size: 12))
                .foregroundStyle(Theme.textSecondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var footer: some View {
        HStack(spacing: 12) {
            hint("↑↓", "Navigate")
            hint("⏎", "Paste")
            hint("⌘P", "Pin")
            hint("⌘⌫", "Delete")
            Spacer()
            Text("\(model.store.items.count)")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.black.opacity(0.18))
    }

    private func hint(_ key: String, _ label: String) -> some View {
        HStack(spacing: 5) {
            Text(key)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(RoundedRectangle(cornerRadius: 5).fill(Color.white.opacity(0.12)))
                .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.white.opacity(0.18), lineWidth: 0.5))
            Text(label).font(.system(size: 10.5)).foregroundStyle(Theme.textSecondary)
        }
    }
}

// MARK: - Image grid tile (Images tab)

struct ImageTile: View {
    let item: ClipItem
    let index: Int
    let selected: Bool
    let onPaste: () -> Void
    let onPin: () -> Void
    let onDelete: () -> Void

    @State private var hovering = false

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 14, style: .continuous)
        // The clear base fixes the cell size; the picture only fills it, so big images cannot stretch the grid.
        Color.clear
            .aspectRatio(1.15, contentMode: .fit)
            .overlay {
                ZStack {
                    Color.white.opacity(0.06)
                    if let f = item.imageFile, let img = ImageCache.thumbnail(file: f) {
                        Image(nsImage: img).resizable().scaledToFill()
                    } else {
                        Image(systemName: "photo").font(.system(size: 22)).foregroundStyle(Theme.textSecondary)
                    }
                }
            }
            .clipShape(shape)
        .overlay(alignment: .top) {
            HStack(spacing: 6) {
                if hovering || selected { tileButton("trash", action: onDelete) }
                Spacer()
                if hovering || selected || item.pinned { tileButton(item.pinned ? "pin.fill" : "pin", action: onPin) }
            }
            .padding(6)
        }
        .overlay(alignment: .bottomLeading) {
            if let size = item.imageSize, hovering || selected {
                Text(size)
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .padding(.horizontal, 7).padding(.vertical, 3)
                    .background(Capsule().fill(Color.black.opacity(0.55)))
                    .padding(6)
            }
        }
        .overlay(shape.stroke(selected ? Theme.accent : Color.white.opacity(0.14), lineWidth: selected ? 2.5 : 1))
        .shadow(color: selected ? Theme.accent.opacity(0.5) : .clear, radius: 10)
        .scaleEffect(selected ? 1.02 : 1)
        .animation(.easeOut(duration: 0.12), value: selected)
        .contentShape(shape)
        .onTapGesture(perform: onPaste)
        .onHover { hovering = $0 }
    }

    private func tileButton(_ name: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: name)
                .font(.system(size: 11, weight: .semibold))
                .frame(width: 24, height: 24)
                .background(Circle().fill(Color.black.opacity(0.55)))
                .foregroundStyle(item.pinned && name.hasPrefix("pin") ? Theme.accent : Color.white)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Row

struct ClipRow: View {
    let item: ClipItem
    let index: Int
    let selected: Bool
    let onPaste: () -> Void
    let onPin: () -> Void
    let onDelete: () -> Void

    @State private var hovering = false

    private static let relative: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return f
    }()

    var body: some View {
        HStack(spacing: 12) {
            tile
            VStack(alignment: .leading, spacing: 3) {
                Text(item.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Text(meta)
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 6)
            trailing
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(selected ? AnyShapeStyle(Theme.accent.opacity(0.28)) : AnyShapeStyle(Theme.glass))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(selected ? Theme.accent.opacity(0.7) : Theme.glassBorder, lineWidth: 1)
        )
        .shadow(color: selected ? Theme.accent.opacity(0.25) : .clear, radius: 8)
        .contentShape(Rectangle())
        .onTapGesture(perform: onPaste)
        .onHover { hovering = $0 }
    }

    private var meta: String {
        let when = Self.relative.localizedString(for: item.date, relativeTo: Date())
        if let name = item.sourceName { return "\(name) · \(when)" }
        return when
    }

    /// Rounded tile that tells the type at a glance: icon, image thumbnail or colour swatch.
    @ViewBuilder private var tile: some View {
        let shape = RoundedRectangle(cornerRadius: 10, style: .continuous)
        if item.kind == .image, let f = item.imageFile, let img = ImageCache.thumbnail(file: f) {
            Image(nsImage: img).resizable().scaledToFill()
                .frame(width: 38, height: 38).clipShape(shape)
                .overlay(shape.stroke(Color.white.opacity(0.25), lineWidth: 1))
        } else if let c = parseHexColor(item.text) {
            shape.fill(c).frame(width: 38, height: 38)
                .overlay(shape.stroke(Color.white.opacity(0.35), lineWidth: 1))
        } else {
            shape.fill(Theme.tile).frame(width: 38, height: 38)
                .overlay(Image(systemName: symbol).font(.system(size: 16, weight: .medium)).foregroundStyle(.white))
                .overlay(shape.stroke(Color.white.opacity(0.25), lineWidth: 1))
        }
    }

    private var symbol: String {
        if item.kind == .image { return "photo" }
        if item.isLink { return "link" }
        return "text.alignleft"
    }

    @ViewBuilder private var trailing: some View {
        HStack(spacing: 8) {
            if hovering || selected {
                iconButton("trash", action: onDelete)
            } else if index < 9 {
                Text("⌘\(index + 1)")
                    .font(.system(size: 10.5, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.35))
            }
            iconButton(item.pinned ? "pin.fill" : "pin", tint: item.pinned ? Theme.accent : Theme.textSecondary, action: onPin)
        }
    }

    private func iconButton(_ name: String, tint: Color = Theme.textSecondary, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: name)
                .font(.system(size: 12, weight: .medium))
                .frame(width: 24, height: 24)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(tint)
    }
}
