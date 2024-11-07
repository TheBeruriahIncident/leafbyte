package com.thebluefolderproject.leafbyte.utils

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.size
import androidx.compose.material3.LocalContentColor
import androidx.compose.material3.minimumInteractiveComponentSize
import androidx.compose.material3.ripple
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.TextUnit
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

@Composable
@Suppress("detekt:complexity:LongParameterList")
fun Text(
    text: String,
    color: Color = Color.Unspecified,
    modifier: Modifier = Modifier,
    size: TextSize = TextSize.STANDARD,
    bold: Boolean = false,
    textAlign: TextAlign? = null,
) {
    Text(
        text = AnnotatedString(text),
        color = color,
        modifier = modifier,
        size = size,
        bold = bold,
        textAlign = textAlign,
    )
}

@Composable
@Suppress("detekt:complexity:LongParameterList")
fun Text(
    text: AnnotatedString,
    color: Color = Color.Unspecified,
    modifier: Modifier = Modifier,
    size: TextSize = TextSize.STANDARD,
    bold: Boolean = false,
    textAlign: TextAlign? = null,
) {
    androidx.compose.material3.Text(
        text = text,
        color = color,
        modifier = modifier,
        fontSize = size.fontSize,
        fontWeight = if (bold) FontWeight.Bold else null,
        textAlign = textAlign,
    )
}

enum class TextSize(internal val fontSize: TextUnit) {
    MAIN_TITLE(45.sp),
    SCREEN_TITLE(20.sp),
    STANDARD(16.sp),
    IN_BUTTON(14.sp),
    FOOTNOTE(12.sp),
}

fun Modifier.description(description: String): Modifier {
    return semantics { contentDescription = description }
}

/**
 * This is a fork of androidx.compose.material3.IconButton v1.3.1. Unfortunately there does not seem to be a way to use the vanilla
 * component without being clipped to a circle.
 */
@Composable
fun IconButton(
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    interactionSource: MutableInteractionSource? = null,
    content: @Composable () -> Unit
) {
    Box(
        modifier =
        modifier
            .minimumInteractiveComponentSize()
            .size(40.0.dp)
            .background(color = Color.Transparent)
            .clickable(
                onClick = onClick,
                enabled = enabled,
                role = Role.Button,
                interactionSource = interactionSource,
                indication =
                ripple(
                    bounded = false,
                    radius = 40.dp / 2
                )
            ),
        contentAlignment = Alignment.Center
    ) {
        CompositionLocalProvider(LocalContentColor provides BUTTON_COLOR, content = content)
    }
}

