import SwiftUI

struct CausalGraphView: View {
    let graph: [String: Any]
    @State private var selectedNode: String? = nil
    @State private var tooltip: (String, CGPoint)? = nil
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Causal Graph").font(.headline)
            GeometryReader { geo in
                ZStack {
                    if let nodes = graph["nodes"] as? [[String: Any]], let edges = graph["edges"] as? [[String: Any]] {
                        let nodeCount = nodes.count
                        let nodeSpacing = geo.size.width / CGFloat(max(nodeCount, 2))
                        // Layout nodes in a circle for better separation
                        let radius = min(geo.size.width, geo.size.height) * 0.35
                        let center = CGPoint(x: geo.size.width/2, y: geo.size.height/2)
                        ForEach(nodes.indices, id: \.self) { idx in
                            let node = nodes[idx]
                            let angle = CGFloat(idx) / CGFloat(nodeCount) * 2 * .pi
                            let x = center.x + radius * cos(angle)
                            let y = center.y + radius * sin(angle)
                            NodeView(label: node["label"] as? String ?? "?", color: colorForNode(id: node["id"] as? String ?? ""), isSelected: selectedNode == (node["id"] as? String))
                                .position(x: x, y: y)
                                .onTapGesture {
                                    selectedNode = node["id"] as? String
                                    tooltip = (node["label"] as? String ?? "?", CGPoint(x: x, y: y-40))
                                }
                        }
                        // Draw edges as lines/arrows
                        ForEach(edges.indices, id: \.self) { idx in
                            let edge = edges[idx]
                            if let fromID = edge["from"] as? String, let toID = edge["to"] as? String,
                               let fromIdx = nodes.firstIndex(where: { $0["id"] as? String == fromID }),
                               let toIdx = nodes.firstIndex(where: { $0["id"] as? String == toID }) {
                                let fromAngle = CGFloat(fromIdx) / CGFloat(nodeCount) * 2 * .pi
                                let toAngle = CGFloat(toIdx) / CGFloat(nodeCount) * 2 * .pi
                                let fromPt = CGPoint(x: center.x + radius * cos(fromAngle), y: center.y + radius * sin(fromAngle))
                                let toPt = CGPoint(x: center.x + radius * cos(toAngle), y: center.y + radius * sin(toAngle))
                                EdgeArrow(from: fromPt, to: toPt, label: edge["label"] as? String, isSelected: false)
                                    .onTapGesture {
                                        tooltip = (edge["label"] as? String ?? "Edge", midpoint(fromPt, toPt))
                                    }
                            }
                        }
                        // Tooltip overlay
                        if let (text, pt) = tooltip {
                            TooltipView(text: text).position(pt)
                                .onTapGesture { tooltip = nil }
                        }
                    } else {
                        Text("No graph data available.").italic()
                    }
                }
            }
            .frame(height: 180)
        }
        .padding(8)
        .background(Color.purple.opacity(0.07))
        .cornerRadius(8)
    }
    func colorForNode(id: String) -> Color {
        switch id {
        case "cause": return .orange
        case "recommendation": return .blue
        case "evidence": return .green
        default: return .gray
        }
    }
    func midpoint(_ a: CGPoint, _ b: CGPoint) -> CGPoint {
        CGPoint(x: (a.x + b.x)/2, y: (a.y + b.y)/2 - 12)
    }
}

struct NodeView: View {
    let label: String
    let color: Color
    var isSelected: Bool = false
    var body: some View {
        VStack {
            Circle().fill(color).frame(width: isSelected ? 40 : 32, height: isSelected ? 40 : 32)
                .overlay(Circle().stroke(isSelected ? Color.yellow : Color.clear, lineWidth: 3))
            Text(label).font(.caption).frame(width: 70)
        }
        .animation(.spring(), value: isSelected)
    }
}

struct EdgeArrow: View {
    let from: CGPoint
    let to: CGPoint
    let label: String?
    var isSelected: Bool = false
    var body: some View {
        ZStack {
            Path { path in
                path.move(to: from)
                path.addLine(to: to)
            }
            .stroke(isSelected ? Color.yellow : Color.secondary, style: StrokeStyle(lineWidth: 2, dash: [4, 2]))
            ArrowHead(from: from, to: to)
                .fill(isSelected ? Color.yellow : Color.secondary)
            if let label = label {
                Text(label).font(.caption2).background(Color.white.opacity(0.7)).position(midpoint(from, to))
            }
        }
    }
    func midpoint(_ a: CGPoint, _ b: CGPoint) -> CGPoint {
        CGPoint(x: (a.x + b.x)/2, y: (a.y + b.y)/2 - 12)
    }
}

struct ArrowHead: Shape {
    let from: CGPoint
    let to: CGPoint
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let angle = atan2(to.y - from.y, to.x - from.x)
        let tip = to
        let length: CGFloat = 10
        let width: CGFloat = 7
        let left = CGPoint(x: tip.x - length * cos(angle) + width * sin(angle), y: tip.y - length * sin(angle) - width * cos(angle))
        let right = CGPoint(x: tip.x - length * cos(angle) - width * sin(angle), y: tip.y - length * sin(angle) + width * cos(angle))
        path.move(to: tip)
        path.addLine(to: left)
        path.move(to: tip)
        path.addLine(to: right)
        return path
    }
}

struct TooltipView: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.caption)
            .padding(8)
            .background(Color(.systemBackground).opacity(0.95))
            .cornerRadius(8)
            .shadow(radius: 4)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.purple, lineWidth: 1)
            )
    }
}
