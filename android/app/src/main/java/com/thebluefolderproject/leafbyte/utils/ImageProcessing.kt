/**
 * Copyright © 2024 Abigail Getman-Pickering. All rights reserved.
 */

package com.thebluefolderproject.leafbyte.utils

data class Size(
    var standardPart: Int = 0,
    var drawingPart: Int = 0,
) {
    fun total(): Int {
        return standardPart + drawingPart
    }

    operator fun plus(increment: Size): Size {
        return Size(standardPart + increment.standardPart, drawingPart + increment.drawingPart)
    }
}

data class Point(val x: Int, val y: Int)

data class ConnectedComponentsInfo(
    val labelToMemberPoint: Map<Int, Point>,
    val emptyLabelToNeighboringOccupiedLabels: Map<Int, Set<Int>>,
    val labelToSize: Map<Int, Size>,
    val equivalenceClasses: UnionFind,
    val labelsOfPointsToIdentify: Map<Point, Int>,
)

val BACKGROUND_LABEL = -1

// Find all the connected components in an image, that is the contiguous areas that are the same ( https://en.wikipedia.org/wiki/Connected-component_labeling ).
// "Occupied" refers to "true" values in the image, and "empty" refers to "false" values in the image.
// E.g. the leaf and scale mark will be occupied connected components, while the holes in the leaf will be "empty" connected components.
// It is assumed that the input layered image will have the main leaf in the 0th spot and, if present, the user drawing in the 1st spot.
// If pointToIdentify is passed in, the label of that point will be returned.
@Suppress("all")
fun labelConnectedComponents(
    image: LayeredIndexableImage,
    pointsToIdentify: List<Point> = listOf(),
): ConnectedComponentsInfo {
    val width = image.width
    val height = image.height
    // Initialize most structures we'll eventually be returning.
    // Maps a label to a point in that component, allowing us to reconstruct the component later.
    var labelToMemberPoint = mutableMapOf<Int, Point>()
    // Tells what occupied components surround any empty component.
    var emptyLabelToNeighboringOccupiedLabels = mutableMapOf<Int, MutableSet<Int>>()
    // Tells the size of each component.
    var labelToSize = mutableMapOf<Int, Size>()
    // A data structure to track what labels actually correspond to the same component (because of the way the algorithm runs, a single blob might get partially marked with one label and partially with another).
    val equivalenceClasses = UnionFind()
    // Negative labels will refer to empty components; positive will refer to occupied components.
    // Track what labels to give out next as we create new groups.
    var nextOccupiedLabel = 1
    var nextEmptyLabel = -2
    // Use -1 as a special label for the area outside the image.
    equivalenceClasses.createSubsetWith(BACKGROUND_LABEL)
    emptyLabelToNeighboringOccupiedLabels[BACKGROUND_LABEL] = mutableSetOf()
    labelToSize[BACKGROUND_LABEL] = Size()
    // As an optimization (speeds this loop up by 40%), save off the isOccupied and label values for the previous y layer for the next loop through.
    lateinit var previousYIsOccupied: List<Boolean>
    lateinit var previousYLabels: List<Int>
    // The labels of any points to identify will be saved.
    // This is indexed in this direction to simplify the process of consolidating equivalent labels later.
    var labelsToPointsToIdentify = mutableMapOf<Int, MutableList<Point>>()
    // Index the pointsToIdentify by their y coordinate to associated x coordinates, to make it easier to identify which rows contain points to identify.
    var pointsToIdentifyYsToXs = mutableMapOf<Int, MutableList<Int>>()
    for (pointToIdentify in pointsToIdentify) {
        if (pointsToIdentifyYsToXs[pointToIdentify.y] == null) {
            pointsToIdentifyYsToXs[pointToIdentify.y] = mutableListOf(pointToIdentify.x)
        } else {
            // Due to strange behavior in Swift 4 (this will change in Swift 5), we can't directly append to a list in a dictionary ( https://stackoverflow.com/a/24535563/1092672 ).
            var pointsToIdentifyXsForY = pointsToIdentifyYsToXs[pointToIdentify.y]!!
            pointsToIdentifyXsForY.add(pointToIdentify.x)
            pointsToIdentifyYsToXs[pointToIdentify.y] = pointsToIdentifyXsForY
        }
    }
    for (y in 0..height - 1) {
        var currentYIsOccupied = mutableListOf<Boolean>()
        // currentYIsOccupied.reserveCapacity(width)
        var currentYLabels = mutableListOf<Int>()
        // currentYLabels.reserveCapacity(width)
        // As an optimization (speeds this loop up by another 40%), save off the isOccupied and label value for the previous x for the next loop through.
        var previousXIsOccupied: Boolean? = null
        var previousXLabel: Int? = null
        for (x in 0..width - 1) {
            val layerWithPixel = image.getLayerWithPixel(x = x, y = y)
            val isOccupied = layerWithPixel > -1
            currentYIsOccupied.add(isOccupied)
            // Check the pixel's neighbors.
            // Note that we're using 4-connectivity ( https://en.wikipedia.org/wiki/Pixel_connectivity ) for speed.
            // Because we've only set the label for pixels we've already iterated over, we only need to check west and north.
            var westIsOccupied: Boolean? = null
            var westLabel: Int? = null
            if (x > 0) {
                westIsOccupied = previousXIsOccupied
                westLabel = previousXLabel
            }
            previousXIsOccupied = isOccupied
            var northIsOccupied: Boolean? = null
            var northLabel: Int? = null
            if (y > 0) {
                northIsOccupied = previousYIsOccupied[x]
                northLabel = previousYLabels[x]
            }
            // Determine what label this pixel should have.
            var label: Int
            if (isOccupied == westIsOccupied) {
                label = westLabel!!
                // If this pixel matches the west and north, those two ought to be equivalent.
                if (isOccupied == northIsOccupied) {
                    equivalenceClasses.combineClassesContaining(westLabel!!, northLabel!!)
                }
            } else if (isOccupied == northIsOccupied) {
                label = northLabel!!
            } else {
                // If this pixel matches neither, it's part of a new component.
                if (isOccupied) {
                    label = nextOccupiedLabel
                    nextOccupiedLabel += 1
                } else {
                    label = nextEmptyLabel
                    nextEmptyLabel -= 1
                }
                // Initialize the new label.
                labelToMemberPoint[label] = Point(x, y)
                emptyLabelToNeighboringOccupiedLabels[label] = mutableSetOf()
                labelToSize[label] = Size()
                equivalenceClasses.createSubsetWith(label)
            }
            // Increment size.
            // If the pixel was on the 1st layer, it's the user drawing.
            // If on the 0th layer, it's the main leaf.
            // If -1, it was unoccupied.
            if (layerWithPixel == 1) {
                labelToSize[label]!!.drawingPart += 1
            } else {
                labelToSize[label]!!.standardPart += 1
            }
            // Update the neighbor map if we have neighboring occupied and empty.
            if (isOccupied) {
                // Note that these are explicit checks rather just "if !westIsOccupied {", because these values are optional.
                if (westIsOccupied == false) {
                    emptyLabelToNeighboringOccupiedLabels[westLabel!!]!!.add(label)
                }
                if (northIsOccupied == false) {
                    emptyLabelToNeighboringOccupiedLabels[northLabel!!]!!.add(label)
                }
            } else {
                if (westIsOccupied == true) {
                    emptyLabelToNeighboringOccupiedLabels[label]!!.add(westLabel!!)
                }
                if (northIsOccupied == true) {
                    emptyLabelToNeighboringOccupiedLabels[label]!!.add(northLabel!!)
                }
            }
            // Any empty pixels on the edge of the image are part of the "outside of the image" component.
            if (!isOccupied && (y == 0 || x == 0 || y == height - 1 || x == width - 1)) {
                equivalenceClasses.combineClassesContaining(label, BACKGROUND_LABEL)
            }
            previousXLabel = label
            currentYLabels.add(label)
        }
        // Check if this y row has any associated points to identify.
        val pointsToIdentifyXs = pointsToIdentifyYsToXs[y]
        if (pointsToIdentifyXs != null) {
            for (pointToIdentifyX in pointsToIdentifyXs!!) {
                // For each associated point to identify, record the association between the point and label.
                val label = currentYLabels[pointToIdentifyX]
                val point = Point(x = pointToIdentifyX, y = y)
                if (labelsToPointsToIdentify[label] == null) {
                    labelsToPointsToIdentify[label] = mutableListOf(point)
                } else {
                    // Due to strange behavior in Swift 4 (this will change in Swift 5), we can't directly append to a list in a dictionary ( https://stackoverflow.com/a/24535563/1092672 ).
                    var pointsForLabel = labelsToPointsToIdentify[label]!!
                    pointsForLabel.add(point)
                    labelsToPointsToIdentify[label] = pointsForLabel
                }
            }
        }
        previousYIsOccupied = currentYIsOccupied
        previousYLabels = currentYLabels
    }
    // -1, the label for the outside of the image, has a fake member point.
    // Let's fix that so it can't break any code that uses the result of this function.
    val outsideOfImageClass = equivalenceClasses.getClassOf(BACKGROUND_LABEL)!!
    val outsideOfImageClassElement =
        equivalenceClasses.classToElements[outsideOfImageClass]!!
            .filter { it != BACKGROUND_LABEL }.firstOrNull()
    if (outsideOfImageClassElement != null) {
        labelToMemberPoint[BACKGROUND_LABEL] = labelToMemberPoint[outsideOfImageClassElement!!]!!
    } else {
        // -1 is in a class of it's own.
        // This means it's useless, so remove it.
        labelToMemberPoint.remove(BACKGROUND_LABEL)
        emptyLabelToNeighboringOccupiedLabels.remove(BACKGROUND_LABEL)
        labelToSize.remove(BACKGROUND_LABEL)
        equivalenceClasses.classToElements.remove(outsideOfImageClass)
    }
    // Update the labels of the points to identify as labels are consolidated.
    var labelsOfPointsToIdentify = mutableMapOf<Point, Int>()
    // "Normalize" by combining equivalent labels.
    for (equivalenceClassElements in equivalenceClasses.classToElements.values) {
        // Because we take the max, the background class will use -1.
        val representative = equivalenceClassElements.maxOrNull()!!
        // Make the member point be the top-most member point in the equivalence.
        // That way the leaf marker is drawn in a place less likely to overlap the leaf.
        val topMostMemberPoint = equivalenceClassElements.map({ labelToMemberPoint[it]!! }).sortedBy { it.y }[0]
        labelToMemberPoint[representative] = topMostMemberPoint
        // Do an initial loop-through including the first element of the class.
        equivalenceClassElements.forEach { label ->
            // The label of the point to identify would now be obsolete, so save off the new canonical label.
            if (labelsToPointsToIdentify[label] != null) {
                for (point in labelsToPointsToIdentify[label]!!) {
                    labelsOfPointsToIdentify[point] = representative
                }
            }
        }
        // Do a second loop-through without the representative element of the class.
        equivalenceClassElements.filter { it != representative }.forEach { label ->
            // Normalize labelToSize.
            labelToSize[representative] = labelToSize[representative]!! + labelToSize[label]!!
            labelToSize.remove(label)
            // Normalize emptyLabelToNeighboringOccupiedLabels.
            emptyLabelToNeighboringOccupiedLabels[representative]!!.addAll(emptyLabelToNeighboringOccupiedLabels[label]!!)
            emptyLabelToNeighboringOccupiedLabels.remove(label)
        }
    }
    return ConnectedComponentsInfo(
        labelToMemberPoint = labelToMemberPoint,
        emptyLabelToNeighboringOccupiedLabels = emptyLabelToNeighboringOccupiedLabels,
        labelToSize = labelToSize,
        equivalenceClasses = equivalenceClasses,
        labelsOfPointsToIdentify = labelsOfPointsToIdentify,
    )
}
