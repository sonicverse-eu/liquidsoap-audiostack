# Include default configuration values
%include "lib/defaults.liq"

# Include library configurations
%include "lib/studio_inputs.liq"

# Create the two studio inputs
studio_a = create_studio_input(mount="studio_a", port=ICECAST_PORT_PRIMARY)
studio_b = create_studio_input(mount="studio_b", port=ICECAST_PORT_SECONDARY)

# Combine live inputs and fallback
radio =
  fallback(
    id="radio_prod",
    track_sensitive=false,
    [studio_a, studio_b, emergency_fallback]
  )


# Include output configurations
%include "lib/icecast_outputs.liq"

# Output a high bitrate mp3 stream using ffmpeg encoder
output_icecast_stream(
  format=%ffmpeg(
    format = "mp3",
    %audio(
      codec = "libmp3lame",
      b = 192k,
      ar = 48000,
      ac = 2,
      q = 0
    )
  ),
  description="HQ Stream (192kbit MP3)",
  mount=ICECAST_MOUNT_MP3,
  source=radio
)

# Output a low bitrate AAC stream
output_icecast_stream(
  format=%fdkaac(
    channels = 2,
    samplerate = 48000,
    bitrate = ICECAST_BITRATE_AAC_LOW,
    afterburner = true,
    aot = 'mpeg4_aac_lc',
    transmux = 'adts',
    sbr_mode = true
  ),
  description="Mobile Stream (96kbit AAC)",
  mount=ICECAST_MOUNT_AAC_LOW,
  source=radio
)

# Output a high bitrate AAC STL stream
output_icecast_stream(
  format=%fdkaac(
    channels = 2,
    samplerate = 48000,
    bitrate = ICECAST_BITRATE_AAC_HIGH,
    afterburner = true,
    aot = 'mpeg4_aac_lc',
    transmux = 'adts',
    sbr_mode = true
  ),
  description="Transport Stream (576kbit AAC)",
  mount=ICECAST_MOUNT_AAC_HIGH,
  source=radio
)

