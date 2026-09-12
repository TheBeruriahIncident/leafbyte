/*
 * Copyright © 2026 Abigail Getman-Pickering. All rights reserved.
 */

package com.thebluefolderproject.leafbyte.settings

import com.thebluefolderproject.leafbyte.serializedsettings.DatasetSpecificSettings
import com.thebluefolderproject.leafbyte.serializedsettings.SerializedSaveLocation
import com.thebluefolderproject.leafbyte.serializedsettings.SerializedSettings

// With the newer Protobuf Editions, it's now possible to put defaults into the proto file, but Protobufs are opaque, less well documented
//   than they first appear, and have unclear long-term API contracts, so we're keeping things simple and specifying in code
private const val DEFAULT_DATASET_NAME = "Herbivory Data"
private const val DEFAULT_SCALE_LENGTH = 10.0f
private const val DEFAULT_SCALE_UNIT = "cm"
private const val DEFAULT_NEXT_SAMPLE_NUMBER = 1

fun SerializedSettings.currentDatasetNameNormalized(): String = normalizeDatasetName(currentDatasetName)
fun normalizeDatasetName(datasetName: String) = datasetName.ifBlank { DEFAULT_DATASET_NAME }

fun SerializedSettings.currentSettings(): DatasetSpecificSettings =
    datasetNameToSettingsMap.getOrElse(
        currentDatasetNameNormalized(),
        DatasetSpecificSettings::getDefaultInstance,
    )

fun SerializedSaveLocation.deserialize(): SaveLocation = SaveLocation.fromSerialized(this)

fun DatasetSpecificSettings.scaleLengthNormalized(): Float = normalizeScaleLength(scaleLength)
fun normalizeScaleLength(scaleLength: Float) = if (scaleLength <= 0) DEFAULT_SCALE_LENGTH else scaleLength

fun DatasetSpecificSettings.scaleUnitNormalized(): String = normalizeScaleUnit(scaleUnit)
fun normalizeScaleUnit(unit: String) = unit.ifBlank { DEFAULT_SCALE_UNIT }

fun DatasetSpecificSettings.nextSampleNumberNormalized(): Int = normalizeNextSampleNumber(nextSampleNumber)
fun normalizeNextSampleNumber(nextSampleNumber: Int) = if (nextSampleNumber <= 0) DEFAULT_NEXT_SAMPLE_NUMBER else nextSampleNumber
