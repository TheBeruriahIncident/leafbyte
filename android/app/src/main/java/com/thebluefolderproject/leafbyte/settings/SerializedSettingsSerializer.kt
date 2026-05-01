/*
 * Copyright © 2024 Abigail Getman-Pickering. All rights reserved.
 */

package com.thebluefolderproject.leafbyte.settings

import androidx.datastore.core.CorruptionException
import androidx.datastore.core.Serializer
import com.google.protobuf.InvalidProtocolBufferException
import com.thebluefolderproject.leafbyte.serializedsettings.SerializedSettings
import java.io.InputStream
import java.io.OutputStream

object SerializedSettingsSerializer : Serializer<SerializedSettings> {
    override val defaultValue: SerializedSettings = SerializedSettings.getDefaultInstance()

    // @Suppress("BlockingMethodInNonBlockingContext")
    override suspend fun readFrom(input: InputStream): SerializedSettings {
        try {
            return SerializedSettings.parseFrom(input)
        } catch (exception: InvalidProtocolBufferException) {
            throw CorruptionException("Cannot read proto.", exception)
        }
    }

    // @Suppress("BlockingMethodInNonBlockingContext")
    override suspend fun writeTo(
        t: SerializedSettings,
        output: OutputStream,
    ) = t.writeTo(output)
}
