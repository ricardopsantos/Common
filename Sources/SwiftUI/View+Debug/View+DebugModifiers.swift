//
//  Created by Ricardo Santos on 01/01/2023.
//  Copyright © 2024 - 2019 Ricardo Santos. All rights reserved.
//

import Foundation
import SwiftUI

// https://blog.stackademic.com/swiftui-hacks-with-custom-modifiers-310c24e7078d

public extension View {
    func displaySize() -> some View {
#if DEBUG
        modifier(SizeDisplayModifier())
#else
        self
#endif
    }
    
    func performanceMetrics() -> some View {
#if DEBUG
        modifier(PerformanceMetricsModifier())
#else
        self
#endif
        
    }
    
    func renderTimeTracker() -> some View {
#if DEBUG
        modifier(RenderTimeModifier())
#else
        self
#endif
    }
    
    func layoutGuides(grid: Bool = true, baseline: Bool = true) -> some View {
#if DEBUG
        modifier(LayoutGuidesModifier(grid: grid, baseline: baseline))
#else
        self
#endif
    }
}

struct LayoutGuidesModifier: ViewModifier {
    let grid: Bool
    let baseline: Bool
    
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    ZStack {
                        if grid {
                            gridOverlay(for: geometry.size)
                        }
                        if baseline {
                            baselineOverlay(for: geometry.size)
                        }
                    }
                }
            )
    }
    
    private func gridOverlay(for size: CGSize) -> some View {
        let gridSpacing: CGFloat = 20
        return ZStack {
            ForEach(0..<Int(size.width / gridSpacing), id: \.self) { i in
                Path { path in
                    let x = CGFloat(i) * gridSpacing
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: size.height))
                }
                .stroke(Color.blue.opacity(0.3), lineWidth: 0.5)
            }
            ForEach(0..<Int(size.height / gridSpacing), id: \.self) { i in
                Path { path in
                    let y = CGFloat(i) * gridSpacing
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y))
                }
                .stroke(Color.blue.opacity(0.3), lineWidth: 0.5)
            }
        }
    }
    
    private func baselineOverlay(for size: CGSize) -> some View {
        let baselineSpacing: CGFloat = 8
        return VStack(spacing: baselineSpacing) {
            ForEach(0..<Int(size.height / baselineSpacing), id: \.self) { _ in
                Divider()
                    .background(Color.red.opacity(0.3))
            }
        }
    }
}

struct RenderTimeModifier: ViewModifier {
    @State private var renderTime: TimeInterval = 0
    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { _ in
                    Color.clear
                        .onAppear {
                            let start = CACurrentMediaTime()
                            DispatchQueue.main.async {
                                let end = CACurrentMediaTime()
                                self.renderTime = end - start
                            }
                        }
                }
            )
            .overlay(
                Text("Rendering: \(String(format: "%.2f", renderTime * 1000)) ms")
                    .font(.caption2)
                    .padding(2)
                    .background(Color.black.opacity(0.7))
                    .foregroundColor(.white)
                    .cornerRadius(4)
                    .padding(4),
                alignment: .bottomLeading
            )
    }
}

class PerformanceMetrics: ObservableObject {
    @Published var cpuUsage: Double = 0
    @Published var memoryUsage: Int64 = 0
    @Published var frameRate: Double = 0
    
    private var timer: Timer?
    private var displayLink: CADisplayLink?
    private var frameCount: Int = 0
    private var startTime: CFTimeInterval = 0
    
    init() {
        // Start the timer to update metrics
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateMetrics()
        }
        
        // Start the display link to calculate frame rate
        startFrameRateMeasurement()
    }
    
    private func updateMetrics() {
        cpuUsage = getCPUUsage()
        memoryUsage = getMemoryUsage()
    }
    
    private func getCPUUsage() -> Double {
        // Fetch CPU usage data
        var cpuInfo = host_cpu_load_info()
        var count = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info>.size) / 4
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &cpuInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            let totalUsage = Double(cpuInfo.cpu_ticks.0 + cpuInfo.cpu_ticks.1 + cpuInfo.cpu_ticks.2 + cpuInfo.cpu_ticks.3)
            let userUsage = Double(cpuInfo.cpu_ticks.0 + cpuInfo.cpu_ticks.1)
            return (userUsage / totalUsage) * 100
        } else {
            return 0
        }
    }
    
    private func getMemoryUsage() -> Int64 {
        var taskInfo = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &taskInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        if kerr == KERN_SUCCESS {
            return Int64(taskInfo.resident_size)
        } else {
            return 0
        }
    }
    
    private func startFrameRateMeasurement() {
        displayLink = CADisplayLink(target: self, selector: #selector(updateFrameRate))
        displayLink?.add(to: .current, forMode: .default)
    }
    
    @objc private func updateFrameRate() {
        frameCount += 1
        if startTime == 0 {
            startTime = CACurrentMediaTime()
        }
        let elapsed = CACurrentMediaTime() - startTime
        if elapsed > 1.0 {
            frameRate = Double(frameCount) / elapsed
            frameCount = 0
            startTime = CACurrentMediaTime()
        }
    }
    
    deinit {
        timer?.invalidate()
        displayLink?.invalidate()
    }
}


struct PerformanceMetricsModifier: ViewModifier {
    @StateObject private var metrics = PerformanceMetrics()
    
    func body(content: Content) -> some View {
        content
            .overlay(
                VStack(alignment: .leading) {
                    Text("CPU: \(String(format: "%.1f", metrics.cpuUsage))%")
                    Text("Memory: \(ByteCountFormatter.string(fromByteCount: metrics.memoryUsage, countStyle: .memory))")
                    Text("FPS: \(String(format: "%.1f", metrics.frameRate))")
                }
                    .font(.caption)
                    .padding(4)
                    .background(Color.black.opacity(0.7))
                    .foregroundColor(.white)
                    .cornerRadius(4)
                    .padding(4),
                alignment: .topLeading
            )
    }
}

struct SizeDisplayModifier: ViewModifier {
    @State private var size: CGSize = .zero
    
    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .preference(key: SizePreferenceKey.self, value: geometry.size)
                }
            )
            .onPreferenceChange(SizePreferenceKey.self) { newSize in
                self.size = newSize
            }
            .overlay(
                Text("W: \(Int(size.width)) H: \(Int(size.height))")
                    .font(.caption)
                    .padding(4)
                    .background(Color.black.opacity(0.7))
                    .foregroundColor(.white)
                    .cornerRadius(4)
                    .padding(4),
                alignment: .topLeading
            )
    }
}

struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

//
// MARK: - Preview
//

#if canImport(SwiftUI) && DEBUG
fileprivate extension Common_Preview {
    struct DebugBackgroundTestView: View {
        public init() {}
        public var body: some View {
            VStack {
                Text("layoutGuides").padding(20).layoutGuides(baseline: false)
                Text("renderTimeTracker").padding(20).renderTimeTracker()
                Text("performanceMetrics").padding(20).performanceMetrics()
                Text("displaySize").padding(20).displaySize()
                
            }
        }
    }
}

@available(iOS 17, *)
#Preview {
    Common_Preview.DebugBackgroundTestView()
}

#endif
