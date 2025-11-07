# Studio inputs configuration - common for all stations

# Listen on all hostnames
settings.harbor.bind_addrs := ["0.0.0.0"]

# Get SRT passphrase for encryption
ICECAST_PASS = environment.get("ICECAST_PASS")


# Note: SILENCE_CONTROL_PATH and is_silence_detection_enabled() are defined in defaults.liq

# Function to create a studio SRT input with silence detection and buffering
def create_studio_input(~mount, ~port) =
  # Create Harbor (SRT) Input - use the provided mount and port so each studio
  # registers a unique mountpoint and port instead of the hardcoded "live".
  studio =
      input.harbor(
        mount,
        port=port,
        password=ICECAST_PASS
      )

  # on_connect/on_disconnect callbacks receive at least one argument (connection info)
  # we ignore the argument but must accept it to satisfy the expected type
  # on_connect expects a callback that receives connection info; accept and ignore it
  studio.on_connect(fun (_) -> log_event(mount, "connected"), synchronous=false)
  # on_disconnect expects a zero-argument callback
  studio.on_disconnect(
    fun () -> log_event(mount, "disconnected"),
    synchronous=false
  )

  # Create version with silence detection and stripping
  studio_with_detect =
    blank.detect(
      id="detect_#{mount}",
      max_blank=SILENCE_SWITCH_SECONDS,
      min_noise=AUDIO_VALID_SECONDS,
      studio
    )

  # Register callbacks for blank and noise detection
  studio_with_detect.on_blank(
    synchronous=false,
    fun () ->
      begin
        levels = null.get(studio_with_detect.dB_levels())

        # Format dB levels as string, rounded to 1 decimal place
        level_strs =
          list.map(fun (x) -> string.float(decimal_places=1, x), levels)
        db_str =
          string.concat(
            separator=", ",
            level_strs
          )
        log_event(
          mount,
          "silence detected (#{db_str} dB)"
        )
      end
  )
  studio_with_detect.on_noise(
    synchronous=false,
    fun () ->
      begin
        levels = null.get(studio_with_detect.dB_levels())

        # Format dB levels as string, rounded to 1 decimal place
        level_strs =
          list.map(fun (x) -> string.float(decimal_places=1, x), levels)
        db_str =
          string.concat(
            separator=", ",
            level_strs
          )
        log_event(
          mount,
          "audio resumed (#{db_str} dB)"
        )
      end
  )

  studio_stripped =
    blank.strip(
      id="stripped_#{mount}",
        max_blank=SILENCE_SWITCH_SECONDS,
        min_noise=AUDIO_VALID_SECONDS,
        studio_with_detect
    )

  # Use switch to select between stripped version and original
  studio_switchable =
    switch(
      id="switch_silence_#{mount}",
      track_sensitive=false,
      [
        ({is_silence_detection_enabled()}, studio_stripped),
        # When silence detection is disabled, use raw studio source
        ({not (is_silence_detection_enabled())}, studio)
      ]
    )

  # Buffer to prevent connection/disconnection latency impact
  buffer(id="buffered_#{mount}", fallible=true, studio_switchable)
end
