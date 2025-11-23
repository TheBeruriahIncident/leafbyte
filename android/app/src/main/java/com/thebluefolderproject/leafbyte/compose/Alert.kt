/*
 * Copyright © 2025 Abigail Getman-Pickering. All rights reserved.
 */

package com.thebluefolderproject.leafbyte.compose

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.wrapContentHeight
import androidx.compose.foundation.layout.wrapContentWidth
import androidx.compose.material3.AlertDialogDefaults
import androidx.compose.material3.BasicAlertDialog
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.MutableState
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.thebluefolderproject.leafbyte.utils.Text
import com.thebluefolderproject.leafbyte.utils.TextSize
import com.thebluefolderproject.leafbyte.utils.log

@Composable
@OptIn(ExperimentalMaterial3Api::class)
fun <AlertTypeT> Alert(
    currentAlert: MutableState<AlertTypeT?>,
    getAlertTitle: (AlertTypeT) -> String,
    getAlertMessage: (AlertTypeT) -> String,
) {
    if (currentAlert.value == null) {
        return
    }
    log("Displaying alert for ${currentAlert.value}")

    val currentAlertValue = currentAlert.value
    val alertTitle: String
    val alertMessage: String
    if (currentAlertValue != null) {
        alertTitle = getAlertTitle(currentAlertValue)
        alertMessage = getAlertMessage(currentAlertValue)
    } else {
        // This handles a (perhaps theoretical) case where the alert is closing but in the middle of one last recompose
        alertTitle = ""
        alertMessage = ""
    }

    BasicAlertDialog(
        onDismissRequest = { currentAlert.value = null },
    ) {
        Surface(
            modifier =
                Modifier
                    .wrapContentWidth()
                    .wrapContentHeight(),
            shape = MaterialTheme.shapes.large,
            tonalElevation = AlertDialogDefaults.TonalElevation,
        ) {
            Column(modifier = Modifier.padding(20.dp)) {
                Text(
                    text = alertTitle,
                    size = TextSize.SCREEN_TITLE,
                    bold = true,
                )
                Spacer(modifier = Modifier.height(10.dp))
                Text(
                    text = alertMessage,
                )
                Spacer(modifier = Modifier.height(10.dp))
                TextButton(
                    onClick = { currentAlert.value = null },
                    modifier = Modifier.align(Alignment.End),
                ) {
                    Text("OK")
                }
            }
        }
    }
}
