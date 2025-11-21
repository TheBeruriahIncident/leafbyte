/**
 * Copyright © 2024 Abigail Getman-Pickering. All rights reserved.
 */

package com.thebluefolderproject.leafbyte.compose

import android.net.Uri
import android.os.Build
import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.absolutePadding
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Scaffold
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.snapshots.SnapshotStateList
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.tooling.preview.Devices
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.thebluefolderproject.leafbyte.R
import com.thebluefolderproject.leafbyte.activity.LeafByteNavKey
import com.thebluefolderproject.leafbyte.utils.BUTTON_COLOR
import com.thebluefolderproject.leafbyte.utils.Text
import com.thebluefolderproject.leafbyte.utils.TextSize
import com.thebluefolderproject.leafbyte.utils.TopAppBar
import com.thebluefolderproject.leafbyte.utils.addToLeftAndRight
import com.thebluefolderproject.leafbyte.utils.appendLink
import com.thebluefolderproject.leafbyte.utils.resourceToUri

@Composable
fun AppAwareTutorialScreen(backStack: SnapshotStateList<Any>) {
    TutorialScreen(
        onPressingBack = {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.VANILLA_ICE_CREAM) {
                // Javadoc doesn't say this is only from API 35, but the linter does, and CI fails otherwise
                backStack.removeLast()
            } else {
                backStack.removeAt(backStack.lastIndex)
            }
        },
        onPressingHome = {
            backStack.clear()
            backStack.add(LeafByteNavKey.MainScreen)
        },
        onPressingNext = { exampleImageUri ->
            backStack.add(LeafByteNavKey.BackgroundRemovalScreen(originalImageUri = exampleImageUri))
        },
    )
}

@Preview(showBackground = true, device = Devices.PIXEL)
@Composable
private fun TutorialScreenPreview() {
    TutorialScreen(onPressingBack = {}, onPressingHome = {}, onPressingNext = {})
}

@OptIn(ExperimentalMaterial3Api::class)
@Suppress("complexity:LongMethod")
@Composable
fun TutorialScreen(
    onPressingBack: () -> Unit,
    onPressingHome: () -> Unit,
    onPressingNext: (exampleImageUri: Uri) -> Unit,
) {
    val exampleImageResourceId = R.drawable.example_leaf
    val exampleImageUri = resourceToUri(exampleImageResourceId)

    Scaffold(
        modifier = Modifier.fillMaxSize(),
        topBar = {
            TopAppBar(onPressingBack = onPressingBack, onPressingHome = onPressingHome)
        },
    ) { paddingValues ->
        Column(
            modifier =
                Modifier
                    .fillMaxSize()
                    .verticalScroll(rememberScrollState())
                    .padding(paddingValues)
                    .absolutePadding(left = 15.dp, right = 15.dp),
            verticalArrangement = Arrangement.spacedBy(10.dp),
            horizontalAlignment = Alignment.Start,
        ) {
            Text("LeafByte lets you quickly and accurately measure leaf area and herbivory.")
            Text("We use images of leaves like this one:")
            Spacer(modifier = Modifier.height(5.dp))
            Box(modifier = Modifier.fillMaxWidth()) {
                Image(
                    painter = painterResource(id = exampleImageResourceId),
                    contentDescription = "Example leaf image",
                    modifier =
                        Modifier
                            .fillMaxWidth(fraction = .7f)
                            .align(Alignment.Center),
                )
            }
            Spacer(modifier = Modifier.height(5.dp))
            Text(
                "Note that the leaf is within four dots that form a square of known size (the \"scale\"). This lets us correct for " +
                    "the angle the image was taken at and determine absolute sizes.*",
            )
            Text("You can take a photo or use an image you already have. For the tutorial, we'll just use this image.")
            Row(
                horizontalArrangement = Arrangement.End,
                modifier = Modifier.fillMaxWidth(),
            ) {
                TextButton(
                    onClick = { onPressingNext(exampleImageUri) },
                ) {
                    Text("Next", color = BUTTON_COLOR)
                }
            }
            Text(
                text =
                    buildAnnotatedString {
                        append("* See ")
                        appendLink(anchorText = "the website", url = "https://zoegp.science/leafbyte-faqs")
                        append(" for a printout with a scale and other details and tips.")
                    },
                modifier = Modifier.fillMaxWidth(),
                size = TextSize.FOOTNOTE,
            )
        }
    }
}
