//
//  BarChartFormatter.swift
//  StepGame
//
//  Created by Tyler Eaden on 10/24/24.
//

import Foundation
import DGCharts

// Custom formatter that makes DGChart Bar Chart data labels ints
class IntegerValueFormatter: NSObject, ValueFormatter {
    func stringForValue(_ value: Double,
                        entry: ChartDataEntry,
                        dataSetIndex: Int,
                        viewPortHandler: ViewPortHandler?) -> String {
        return "\(Int(value))"

    }
}

// Custom formatter that displays only one x-axis label per bar on DGChart Bar Chart
class BarChartFormatter: NSObject, AxisValueFormatter {
    var labels: [String] = []
    
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        let index = Int(value)
        if index >= 0 && index < labels.count {
            return labels[index]
        } else {
            return ""
        }
    }
}
