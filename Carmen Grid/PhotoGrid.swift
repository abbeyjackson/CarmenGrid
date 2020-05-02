//
//  PhotoGrid.swift
//  Carmen Grid
//
//  Created by Abbey Jackson on 2019-03-28.
//  Copyright © 2019 Abbey Jackson. All rights reserved.
//

import UIKit

@IBDesignable class PhotoGrid: UIImageView {
    
    //MARK: Properties
    var drawableWidth: Double {
        return Double(baseImage?.size.width ?? 0)
    }
    var drawableHeight: Double {
        return Double(baseImage?.size.height ?? 0)
    }
    var numberOfColumns: Int = 0
    var numberOfRows: Int = 0
    var columnWidth = 0.0
    var rowHeight = 0.0
    
    var lineWidth: CGFloat = 3
    var lineOffset: CGFloat { return lineWidth / 2 }
    var lineColor: GridColor = .white
    var gridType: GridType = .none
    
    private var smallestSide: Double {
        return Double(min(drawableWidth, drawableHeight))
    }
    
    private var aspectRatio: Double {
        return columnWidth / rowHeight
    }
    
    private var baseImage: UIImage?
    override var image: UIImage? {
        didSet {
            if image == nil || baseImage == nil {
                baseImage = image
            }
        }
    }
    
    //MARK: Drawing
    override func draw(_ rect: CGRect) {
        setGuides()
        drawLines()
    }
    
    private func setGuides() {
        switch gridType {
        case .squares:
            columnWidth = smallestSide / 8
            rowHeight = smallestSide / 8
            numberOfColumns = Int(drawableWidth / columnWidth)
            numberOfRows = Int(drawableHeight / rowHeight)
        case .triangles:
            numberOfColumns = 3
            numberOfRows = 3
            columnWidth = drawableWidth / Double((numberOfColumns + 1))
            rowHeight = drawableHeight / Double((numberOfRows + 1))
        case .smallTriangles:
            numberOfColumns = 7
            numberOfRows = 7
            columnWidth = drawableWidth / Double((numberOfColumns + 1))
            rowHeight = drawableHeight / Double((numberOfRows + 1))
        case .none:
            numberOfColumns = 0
            numberOfRows = 0
        }
    }
    
    private func drawLines() {
        guard let baseImage = baseImage else { return }
        UIGraphicsBeginImageContext(baseImage.size)
        baseImage.draw(in: CGRect(origin: CGPoint.zero, size: baseImage.size))
          
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        context.setLineWidth(lineWidth)
        context.setStrokeColor(lineColor.color)
        
        if numberOfRows > 0 && numberOfColumns > 0 {
            drawVerticalLines(on: context)
            drawHorizontalLines(on: context)
            
            if gridType == .triangles || gridType == .smallTriangles {
                drawDownwardLines(on: context)
                drawUpwardLines(on: context)
            }
        }
        
        context.strokePath()
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        self.image = newImage
    }
    
    //MARK: Line Calculations
    private func drawVerticalLines(on context: CGContext) {
        let centerX = drawableWidth/2
        for i in 0...(numberOfColumns + 1)/2 {
            let verticalCooridinateTop = CGFloat(centerX - columnWidth * Double(i))
            let startPointTop = CGPoint(x: verticalCooridinateTop, y: 0.0)
            let endPointTop = CGPoint(x: verticalCooridinateTop, y: CGFloat(drawableHeight))
            context.move(to: startPointTop)
            context.addLine(to: endPointTop)
            
            let verticalCooridinateBottom = CGFloat(columnWidth * Double(i) + centerX)
            let startPointBottom = CGPoint(x: verticalCooridinateBottom, y: 0.0)
            let endPointBottom = CGPoint(x: verticalCooridinateBottom, y: CGFloat(drawableHeight))
            context.move(to: startPointBottom)
            context.addLine(to: endPointBottom)
        }
    }
    
    private func drawHorizontalLines(on context: CGContext) {
        let centerY = drawableHeight/2
        for j in 0...numberOfRows + 1 {
            let horizontalCoordinateLeft = CGFloat(centerY - rowHeight * Double(j))
            let startPointLeft = CGPoint(x: 0.0, y: horizontalCoordinateLeft)
            let endPointLeft = CGPoint(x: CGFloat(drawableWidth), y: horizontalCoordinateLeft)
            context.move(to: startPointLeft)
            context.addLine(to: endPointLeft)
            
            let horizontalCoordinateRight = CGFloat(rowHeight * Double(j) + centerY)
            let startPointRight = CGPoint(x: 0.0, y: horizontalCoordinateRight)
            let endPointRight = CGPoint(x: CGFloat(drawableWidth), y: horizontalCoordinateRight)
            context.move(to: startPointRight)
            context.addLine(to: endPointRight)
        }
    }
    
    private func drawDownwardLines(on context: CGContext) {
        for i in 0...numberOfColumns + 1 {
            let leftStartX = CGFloat(columnWidth * Double(i))
            let leftStartPoint = CGPoint(x: leftStartX, y: 0.0)
            let leftEndY = CGFloat(drawableHeight - rowHeight * Double(i))
            let leftEndPoint = CGPoint(x: CGFloat(drawableWidth), y: leftEndY)
            context.move(to: leftStartPoint)
            context.addLine(to: leftEndPoint)
            
            let rightStartX = CGFloat(drawableWidth - columnWidth * Double(i))
            let rightStartPoint = CGPoint(x: rightStartX, y: 0.0)
            let rightEndY = CGFloat(drawableHeight - (rowHeight * Double(i)))
            let rightEndPoint = CGPoint(x: 0.0, y: rightEndY)
            context.move(to: rightStartPoint)
            context.addLine(to: rightEndPoint)
        }
    }
    
    private func drawUpwardLines(on context: CGContext) {
        for j in 1...numberOfRows + 1 {
            let leftStartY = CGFloat(rowHeight * Double(j)) + (lineWidth / 2)
            let leftStartPoint = CGPoint(x: 0.0, y: leftStartY)
            let leftEndX = CGFloat(drawableWidth - columnWidth * Double(j))
            let leftEndPoint = CGPoint(x: leftEndX, y: CGFloat(drawableHeight))
            context.move(to: leftStartPoint)
            context.addLine(to: leftEndPoint)

            let rightStartPoint = CGPoint(x: CGFloat(drawableWidth), y: CGFloat(rowHeight * Double(j)))
            let rightEndPoint = CGPoint(x: CGFloat(columnWidth * Double(j)), y: CGFloat(drawableHeight))
            context.move(to: rightStartPoint)
            context.addLine(to: rightEndPoint)
        }
    }
    
    private func updateVisible() {
        setNeedsDisplay()
        setNeedsLayout()
        draw(self.bounds)
        layoutIfNeeded()
    }
}

private typealias PublicAPI = PhotoGrid
extension PublicAPI {
    func swapGrid(completion: (_ newGridType: GridType) -> ()) {
        gridType = GridType(rawValue: gridType.rawValue + 1) ?? .none
        updateVisible()
        completion(gridType)
    }
    
    func swapLineColor(completion: (_ newGridColor: GridColor) -> ()) {
        lineColor = GridColor(rawValue: lineColor.rawValue + 1) ?? .white
        updateVisible()
        completion(lineColor)
    }
    
    func set(type: GridType, color: GridColor? = nil) {
        self.gridType = type
        self.lineColor = color ?? .white
        self.updateVisible()
    }
}
