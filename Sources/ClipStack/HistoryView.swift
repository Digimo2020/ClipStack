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

// MARK: - Main view

struct HistoryView: View {
    @ObservedObject var model: PanelModel
    @FocusState private var searchFocused: Bool

    var body: some View {
        let items = model.visible
        VStack(spacing: 0) {
            header
            Divider().opacity(0.4)
            if items.isEmpty {
                emptyState
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 2) {
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
                        .padding(8)
                    }
                    .onChange(of: model.selectedID) { _, id in
                        guard let id else { return }
                        withAnimation(.easeOut(duration: 0.1)) { proxy.scrollTo(id) }
                    }
                }
            }
            Divider().opacity(0.4)
            footer
        }
        .onAppear { searchFocused = true }
        .onChange(of: model.focusTick) { _, _ in searchFocused = true }
    }

    private var header: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                TextField("Search clipboard history", text: $model.query)
                    .textFieldStyle(.plain)
                    .font(.system(size: 15))
                    .focused($searchFocused)
                if !model.query.isEmpty {
                    Button { model.query = "" } label: {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(.tertiary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(.primary.opacity(0.07)))

            HStack(spacing: 6) {
                ForEach(ClipFilter.allCases) { f in
                    Button { model.filter = f } label: {
                        Text(f.rawValue)
                            .font(.system(size: 11.5, weight: .medium))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(model.filter == f ? Color.accentColor : Color.primary.opacity(0.07)))
                            .foregroundStyle(model.filter == f ? Color.white : Color.secondary)
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
        }
        .padding(12)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Spacer()
            Image(systemName: model.query.isEmpty ? "doc.on.clipboard" : "magnifyingglass")
                .font(.system(size: 34, weight: .light))
                .foregroundStyle(.tertiary)
            Text(model.query.isEmpty ? "Nothing here yet" : "No results")
                .font(.system(size: 14, weight: .medium))
            Text(model.query.isEmpty ? "Copy something and it will show up here." : "Try a different search or filter.")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var footer: some View {
        HStack(spacing: 14) {
            hint("↑↓", "Navigate")
            hint("⏎", "Paste")
            hint("⌘P", "Pin")
            hint("⌘⌫", "Delete")
            Spacer()
            Text("\(model.store.items.count) items")
                .font(.system(size: 10.5))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }

    private func hint(_ key: String, _ label: String) -> some View {
        HStack(spacing: 4) {
            Text(key)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .padding(.horizontal, 5)
                .padding(.vertical, 1.5)
                .background(RoundedRectangle(cornerRadius: 4).fill(.primary.opacity(0.1)))
            Text(label).font(.system(size: 10.5)).foregroundStyle(.secondary)
        }
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
        HStack(alignment: .top, spacing: 10) {
            icon
            VStack(alignment: .leading, spacing: 4) {
                content
                HStack(spacing: 4) {
                    if let name = item.sourceName { Text(name) }
                    Text("·")
                    Text(Self.relative.localizedString(for: item.date, relativeTo: Date()))
                }
                .font(.system(size: 10.5))
                .foregroundStyle(Color.primary.opacity(selected ? 0.65 : 0.5))
                .lineLimit(1)
            }
            Spacer(minLength: 4)
            trailing
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(selected ? Color.accentColor.opacity(0.28) : Color.clear)
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onPaste)
        .onHover { hovering = $0 }
    }

    @ViewBuilder private var icon: some View {
        if let img = ImageCache.appIcon(bundleID: item.sourceBundleID) {
            Image(nsImage: img).resizable().frame(width: 24, height: 24)
        } else {
            Image(systemName: item.kind == .image ? "photo" : "doc.text")
                .frame(width: 24, height: 24)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder private var content: some View {
        switch item.kind {
        case .text:
            Text((item.text ?? "").prefix(400))
                .font(.system(size: 13, design: item.isLink ? .default : .default))
                .foregroundStyle(item.isLink ? Color.accentColor : Color.primary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
        case .image:
            HStack(spacing: 8) {
                if let f = item.imageFile, let img = ImageCache.thumbnail(file: f) {
                    Image(nsImage: img)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 200, maxHeight: 64, alignment: .leading)
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 6, style: .continuous).stroke(.primary.opacity(0.12), lineWidth: 0.5))
                }
                if let s = item.imageSize {
                    Text(s).font(.system(size: 11)).foregroundStyle(.secondary)
                }
            }
        }
    }

    @ViewBuilder private var trailing: some View {
        if hovering || selected {
            HStack(spacing: 6) {
                iconButton(item.pinned ? "pin.slash.fill" : "pin", action: onPin)
                iconButton("trash", action: onDelete)
            }
        } else if item.pinned {
            Image(systemName: "pin.fill").font(.system(size: 10)).foregroundStyle(.orange)
        } else if index < 9 {
            Text("⌘\(index + 1)").font(.system(size: 10.5, design: .rounded)).foregroundStyle(.tertiary)
        }
    }

    private func iconButton(_ name: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: name)
                .font(.system(size: 11))
                .frame(width: 22, height: 22)
                .background(Circle().fill(.primary.opacity(0.1)))
        }
        .buttonStyle(.plain)
        .foregroundStyle(.secondary)
    }
}
