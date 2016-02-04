vec4 resultCol;
vec4 textureCol;

extern vec2 stepSize;

vec4 effect(vec4 col, Image texture, vec2 texture_coords, vec2 screen_coords)
{
    number alpha = 4*texture2D( texture, texture_coords ).a;
    alpha -= texture2D( texture, texture_coords + vec2( stepSize.x, 0.0f ) ).a;
    alpha -= texture2D( texture, texture_coords + vec2( -stepSize.x, 0.0f ) ).a;
    alpha -= texture2D( texture, texture_coords + vec2( 0.0f, stepSize.y ) ).a;
    alpha -= texture2D( texture, texture_coords + vec2( 0.0f, -stepSize.y ) ).a;

    textureCol = texture2D( texture, texture_coords );
    resultCol = textureCol + vec4( 1 - textureCol.rgb, alpha );

    return resultCol;
}
