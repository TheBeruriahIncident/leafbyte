package com.thebluefolderproject.leafbyte.utils

import androidx.compose.foundation.layout.size
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.TextUnit
import androidx.compose.ui.unit.sp

enum class TextSize(val fontSize: TextUnit) {
    MAIN_TITLE(45.sp),
    SCREEN_TITLE(20.sp),
    STANDARD(16.sp),
    IN_BUTTON(14.sp),
    FOOTNOTE(12.sp),
}

@Composable
fun Text(
    text: String,
    modifier: Modifier = Modifier,
    size: TextSize = TextSize.STANDARD,
    bold: Boolean = false,
    textAlign: TextAlign? = null,
) {
    androidx.compose.material3.Text(
        text = text,
        modifier = modifier,
        fontSize = size.fontSize,
        fontWeight = if(bold) FontWeight.Bold else null,
        textAlign = textAlign,
    )
}

@Composable
fun Text(
    text: AnnotatedString,
    modifier: Modifier = Modifier,
    size: TextSize = TextSize.STANDARD,
    bold: Boolean = false,
    textAlign: TextAlign? = null,
) {
    androidx.compose.material3.Text(
        text = text,
        modifier = modifier,
        fontSize = size.fontSize,
        fontWeight = if(bold) FontWeight.Bold else null,
        textAlign = textAlign,
    )
}
