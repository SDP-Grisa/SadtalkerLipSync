from gtts import gTTS
import os

TEXT_FILE = "text.txt"
OUTPUT = "output_audio.mp3"

with open(TEXT_FILE, "r", encoding="utf-8") as f:
    text = f.read().strip()

tts = gTTS(text=text, lang="en")
tts.save(OUTPUT)

print("Audio generated:", OUTPUT)
