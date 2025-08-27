package javax.annotation

/**
 * This is a ridiculous hack. Protobuf generates with the very deprecated javax.annotation.Generated, which only has SOURCE retention, and
 * only annotates some classes. This is just bad behavior from the protobuf library, and the maintainers aren't willing to fix it or allow a
 * fix. This class shadows in the Generated annotation but with RUNTIME retention so that tooling like Jacoco will recognize it. Even still,
 * not annotating all classes means that Jacoco won't recognize all generated classes as generated.
 */
@Target(
    AnnotationTarget.ANNOTATION_CLASS,
    AnnotationTarget.CONSTRUCTOR,
    AnnotationTarget.FIELD,
    AnnotationTarget.LOCAL_VARIABLE,
    AnnotationTarget.FUNCTION,
    AnnotationTarget.PROPERTY_GETTER,
    AnnotationTarget.PROPERTY_SETTER,
    AnnotationTarget.FILE,
    AnnotationTarget.VALUE_PARAMETER,
    AnnotationTarget.CLASS,
)
@Retention(
    AnnotationRetention.RUNTIME,
)
annotation class Generated(
    vararg val value: String,
    val date: String = "",
    val comments: String = "",
)
