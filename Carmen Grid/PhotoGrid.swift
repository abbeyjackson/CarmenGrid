//
//  PhotoGrid.swift
//  Carmen Grid
//
//  Created by Abbey Jackson on 2019-03-28.
//  Copyright © 2019 Abbey Jackson. All rights reserved.
//

import UIKit

@IBDesignable class PhotoGrid: UIView {
    
    //MARK: Properties
    var drawableWidth: CGFloat {
        return frame.size.width
    }
    var drawableHeight: CGFloat {
        return frame.size.height
    }
    var numberOfColumns: Int = 0
    var numberOfRows: Int = 0
    var columnWidth: Int = 0
    var rowHeight: Int = 0
    
    var lineWidth: CGFloat = 3.5
    var lineColor: GridColor = .white
    var gridType: GridType = .none
    
    private var smallestSide: CGFloat {
        return min(drawableWidth, drawableHeight)
    }
    
    private var aspectRatio: CGFloat {
        return CGFloat(columnWidth / rowHeight)
    }
    
    //MARK: Drawing
    override func draw(_ rect: CGRect) {
        print("drawing grid type \(gridType)")
        setGuides()
        drawLines()
    }
    
    private func setGuides() {
        switch gridType {
        case .squares:
            columnWidth = Int(smallestSide / 4)
            rowHeight = Int(smallestSide / 4)
            numberOfColumns = Int(drawableWidth) / columnWidth
            numberOfRows = Int(drawableHeight) / rowHeight
        case .triangles:
            numberOfColumns = 3
            numberOfRows = 3
            columnWidth = Int(drawableWidth) / (numberOfColumns + 1)
            rowHeight = Int(drawableHeight) / (numberOfRows + 1)
        case .smallTriangles:
            numberOfColumns = 6
            numberOfRows = 6
            columnWidth = Int(drawableWidth) / (numberOfColumns + 1)
            rowHeight = Int(drawableHeight) / (numberOfRows + 1)
        case .none:
            numberOfColumns = 0
            numberOfRows = 0
        }
    }
    
    private func drawLines() {
        guard numberOfRows > 0 && numberOfColumns > 0 else { return }
        
        guard let context = UIGraphicsGetCurrentContext() else {
            return }
        print("context exists, drawing lines")
        
        context.setLineWidth(lineWidth)
        context.setStrokeColor(lineColor.color)
        
        drawVerticalLines(on: context)
        drawHorizontalLines(on: context)
        
        if gridType == .triangles || gridType == .smallTriangles {
            drawDownwardLines(on: context)
            drawUpwardLines(on: context)
        }
    }
    
    //MARK: Line Calculations
    private func drawVerticalLines(on context: CGContext) {
        for i in 0...numberOfColumns + 1 {
            var startPoint = CGPoint.zero
            var endPoint = CGPoint.zero
            startPoint.x = CGFloat(columnWidth * i) + (lineWidth / 2)
            startPoint.y = 0.0
            endPoint.x = startPoint.x
            endPoint.y = drawableHeight
            context.move(to: CGPoint(x: startPoint.x, y: startPoint.y))
            context.addLine(to: CGPoint(x: endPoint.x, y: endPoint.y))
            context.strokePath()
        }
    }
    
    private func drawHorizontalLines(on context: CGContext) {
        for j in 0...numberOfRows + 1 {
            var startPoint = CGPoint.zero
            var endPoint = CGPoint.zero
            startPoint.x = 0.0
            startPoint.y = CGFloat(rowHeight * j) + (lineWidth / 2)
            endPoint.x = drawableWidth
            endPoint.y = startPoint.y
            context.move(to: CGPoint(x: startPoint.x, y: startPoint.y))
            context.addLine(to: CGPoint(x: endPoint.x, y: endPoint.y))
            context.strokePath()
        }
    }
    
    private func drawDownwardLines(on context: CGContext) {
        for i in 0...numberOfColumns + 1 {
            var leftStartPoint = CGPoint.zero
            var leftEndPoint = CGPoint.zero
            leftStartPoint.x = CGFloat(columnWidth * i) + (lineWidth / 2)
            leftStartPoint.y = 0.0
            leftEndPoint.x = drawableWidth
            leftEndPoint.y = drawableHeight - CGFloat(rowHeight * i)
            context.move(to: CGPoint(x: leftStartPoint.x, y: leftStartPoint.y))
            context.addLine(to: CGPoint(x: leftEndPoint.x, y: leftEndPoint.y))
            
            var rightStartPoint = CGPoint.zero
            var rightEndPoint = CGPoint.zero
            rightStartPoint.x = drawableWidth - CGFloat(columnWidth * i)
            rightStartPoint.y = 0.0
            rightEndPoint.x = 0.0
            rightEndPoint.y = drawableHeight - CGFloat((rowHeight * i))
            context.move(to: CGPoint(x: rightStartPoint.x, y: rightStartPoint.y))
            context.addLine(to: CGPoint(x: rightEndPoint.x, y: rightEndPoint.y))
            
            context.strokePath()
        }
    }
    
    private func drawUpwardLines(on context: CGContext) {
        for j in 1...numberOfRows + 1 {
            var leftStartPoint = CGPoint.zero
            var leftEndPoint = CGPoint.zero
            leftStartPoint.x = 0.0
            leftStartPoint.y = CGFloat(rowHeight * j) + (lineWidth / 2)
            leftEndPoint.x = drawableWidth - CGFloat(columnWidth * j)
            leftEndPoint.y = drawableHeight
            context.move(to: CGPoint(x: leftStartPoint.x, y: leftStartPoint.y))
            context.addLine(to: CGPoint(x: leftEndPoint.x, y: leftEndPoint.y))
            
            var rightStartPoint = CGPoint.zero
            var rightEndPoint = CGPoint.zero
            rightStartPoint.x = drawableWidth
            rightStartPoint.y = CGFloat(rowHeight * j)
            rightEndPoint.x = CGFloat(columnWidth * j)
            rightEndPoint.y = drawableHeight
            context.move(to: CGPoint(x: rightStartPoint.x, y: rightStartPoint.y))
            context.addLine(to: CGPoint(x: rightEndPoint.x, y: rightEndPoint.y))
            
            context.strokePath()
        }
    }
    
    private func updateVisible() {
        print("update visible")
        setNeedsDisplay()
        setNeedsLayout()
        draw(self.bounds)
        layoutIfNeeded()
    }
}

private typealias PublicAPI = PhotoGrid
extension PublicAPI {
    func swapGrid(completion: (_ newGridType: GridType) -> ()) {
        print("swap from current \(gridType.rawValue)")
        gridType = GridType(rawValue: gridType.rawValue + 1) ?? .none
        updateVisible()
        completion(gridType)
    }
    
    func swapLineColor(completion: (_ newGridColor: GridColor) -> ()) {
        print("swap color")
        lineColor = GridColor(rawValue: lineColor.rawValue + 1) ?? .white
        updateVisible()
        completion(lineColor)
    }
    
    func set(type: GridType?, color: GridColor?) {
        print("grid set called")
        self.gridType = type ?? .none
        self.lineColor = color ?? .white
        self.updateVisible()
    }
}
