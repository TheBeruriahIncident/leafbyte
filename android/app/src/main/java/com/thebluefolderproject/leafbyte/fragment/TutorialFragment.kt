@file:Suppress("all")
/**
 * Copyright © 2024 Abigail Getman-Pickering. All rights reserved.
 */

package com.thebluefolderproject.leafbyte.fragment

import android.content.ContentResolver
import android.net.Uri
import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.tooling.preview.Devices
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.thebluefolderproject.leafbyte.R
import com.thebluefolderproject.leafbyte.utils.BUTTON_COLOR
import com.thebluefolderproject.leafbyte.utils.IconButton
import com.thebluefolderproject.leafbyte.utils.Text
import com.thebluefolderproject.leafbyte.utils.TextSize

@Preview(showBackground = true, device = Devices.PIXEL)
@Composable
private fun TutorialScreenPreview() {
    TutorialScreen({})
}

@OptIn(ExperimentalMaterial3Api::class)
@Suppress("detekt:complexity:LongMethod")
@Composable
fun TutorialScreen(onPressingNext: (uri: Uri) -> Unit) {
    val uri = resourceToUri(R.drawable.example_leaf)

    Column(
        modifier =
            Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(10.dp),
        verticalArrangement = Arrangement.spacedBy(10.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        TopAppBar(
            navigationIcon = {
                TextButton(
                    onClick = { }, // TODO: onPressingNext()
                ) {
                    Text("Back", color = BUTTON_COLOR)
                }
            },
            actions = {
                IconButton(
                    onClick = {},
                ) {
                    Icon(painterResource(id = R.drawable.home), tint = BUTTON_COLOR, contentDescription = null)
                }
            },
            title = {},
        )
        Text(
            text = "LeafByte lets you quickly and accurately measure leaf area and herbivory.",
            modifier = Modifier.fillMaxWidth(),
        )
        Text(
            text = "We use images of leaves like this one:",
            modifier = Modifier.fillMaxWidth(),
        )
        Image(
            painter = painterResource(id = R.drawable.example_leaf),
            contentDescription = "Camera icon",
            @Suppress("detekt:style:MagicNumber")
            Modifier.fillMaxWidth(.7f),
        )
        Text(
            text =
                "Note that the leaf is within four dots that form a square of known size (the \"scale\"). This lets us correct for " +
                    "the angle the image was taken at and determine absolute sizes.*",
            modifier = Modifier.fillMaxWidth(),
        )
        Text(
            text = "You can take a photo or use an image you already have. For the tutorial, we'll just use this image.",
            modifier = Modifier.fillMaxWidth(),
        )
        Spacer(modifier = Modifier.height(5.dp))
        Text(
            // TODO link this and iphone
            text = "*See the website for a printout with a scale and other details and tips.",
            modifier = Modifier.fillMaxWidth(),
            size = TextSize.FOOTNOTE,
        )
        Row(
            horizontalArrangement = Arrangement.End,
            modifier = Modifier.fillMaxWidth(),
        ) {
            TextButton(
                onClick = { onPressingNext(uri) },
            ) {
                Text("Next", color = BUTTON_COLOR)
            }
        }
    }
}

@Composable
fun resourceToUri(resID: Int): Uri {
    val resources = LocalContext.current.resources
    return Uri.parse(
        ContentResolver.SCHEME_ANDROID_RESOURCE + "://" +
            resources.getResourcePackageName(resID) + '/'.toString() +
            resources.getResourceTypeName(resID) + '/'.toString() +
            resources.getResourceEntryName(resID),
    )
}
