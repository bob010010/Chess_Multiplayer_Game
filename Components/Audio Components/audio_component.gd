extends AudioStreamPlayer2D

# Plays the audio sound
func play_weapon_sound(clip: AudioStream) -> void:
	#print(str(clip))
	stream = clip
	pitch_scale = randf_range(0.9, 1.1)
	play()
