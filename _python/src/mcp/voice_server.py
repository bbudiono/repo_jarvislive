"""
* Purpose: MCP server for voice processing (speech-to-text, text-to-speech, ElevenLabs)
* Issues & Complexity Summary: Real-time audio processing with multiple voice synthesis options
* Key Complexity Drivers:
  - Logic Scope (Est. LoC): ~300
  - Core Algorithm Complexity: High (audio processing + real-time streaming)
  - Dependencies: ElevenLabs, Whisper, audio libraries
  - State Management Complexity: Medium (audio session management)
  - Novelty/Uncertainty Factor: Medium
* AI Pre-Task Self-Assessment: 85%
* Problem Estimate: 85%
* Initial Code Complexity Estimate: 85%
* Final Code Complexity: 88%
* Overall Result Score: 86%
* Key Variances/Learnings: Complex audio processing pipeline with multiple synthesis options
* Last Updated: 2025-06-26
"""

import asyncio
import base64
import io
import logging
import time
import tempfile
from typing import Dict, Any, Optional, List
import os

# Audio processing libraries
import librosa
import soundfile as sf
import numpy as np

# Voice synthesis
from elevenlabs import VoiceSettings
from elevenlabs.client import ElevenLabs

# Speech recognition
import whisper

import redis.asyncio as redis

logger = logging.getLogger(__name__)


class VoiceMCPServer:
    """MCP server for voice processing capabilities"""

    def __init__(self, redis_client: Optional[redis.Redis] = None):
        self.redis_client = redis_client
        self.server_name = "voice"
        self.is_running = False
        self.capabilities = [
            "speech_to_text",
            "text_to_speech",
            "voice_synthesis",
            "audio_processing",
            "voice_cloning",
        ]

        # ElevenLabs configuration
        self.elevenlabs_api_key = os.getenv("ELEVENLABS_API_KEY", "")
        self.elevenlabs_client = None

        # Whisper configuration
        self.whisper_model = None
        self.whisper_model_name = "base"  # Options: tiny, base, small, medium, large

        # Voice configurations
        self.voice_configs = {
            "default": {
                "voice_id": "21m00Tcm4TlvDq8ikWAM",  # Rachel (ElevenLabs)
                "name": "Rachel",
                "description": "Professional female voice",
                "settings": VoiceSettings(
                    stability=0.5,
                    similarity_boost=0.5,
                    style=0.0,
                    use_speaker_boost=True,
                ),
            },
            "jarvis": {
                "voice_id": "pMsXgVXv3BLzUgSXRplE",  # Male voice
                "name": "Jarvis",
                "description": "AI assistant male voice",
                "settings": VoiceSettings(
                    stability=0.7,
                    similarity_boost=0.6,
                    style=0.1,
                    use_speaker_boost=True,
                ),
            },
            "casual": {
                "voice_id": "EXAVITQu4vr4xnSDxMaL",  # Casual voice
                "name": "Sam",
                "description": "Casual conversational voice",
                "settings": VoiceSettings(
                    stability=0.4,
                    similarity_boost=0.7,
                    style=0.2,
                    use_speaker_boost=False,
                ),
            },
        }

        # Audio processing settings
        self.audio_settings = {
            "sample_rate": 44100,
            "channels": 1,
            "bit_depth": 16,
            "format": "wav",
        }

    async def initialize(self):
        """Initialize the voice MCP server"""
        logger.info("Initializing Voice MCP Server...")

        try:
            # Initialize ElevenLabs client
            if self.elevenlabs_api_key:
                self.elevenlabs_client = ElevenLabs(api_key=self.elevenlabs_api_key)
                logger.info("ElevenLabs client initialized")
            else:
                logger.warning(
                    "ElevenLabs API key not provided - TTS functionality limited"
                )

            # Initialize Whisper model
            await self._initialize_whisper_model()

            # Test voice processing
            await self._test_voice_processing()

            logger.info("Voice MCP Server initialized successfully")

        except Exception as e:
            logger.error(f"Voice MCP Server initialization failed: {str(e)}")
            raise

    async def start(self):
        """Start the voice MCP server"""
        self.is_running = True
        logger.info("Voice MCP Server started")

    async def shutdown(self):
        """Shutdown the voice MCP server"""
        self.is_running = False
        logger.info("Voice MCP Server shut down")

    async def ping(self):
        """Health check for the voice server"""
        if not self.is_running:
            raise RuntimeError("Voice MCP Server is not running")
        return {"status": "healthy", "timestamp": time.time()}

    async def speech_to_text(
        self,
        audio_data: bytes,
        format: str = "wav",
        sample_rate: int = 44100,
        language: Optional[str] = None,
    ) -> Dict[str, Any]:
        """Convert speech to text using Whisper"""
        start_time = time.time()

        try:
            if not self.whisper_model:
                raise RuntimeError("Whisper model not initialized")

            # Create temporary file for audio processing
            with tempfile.NamedTemporaryFile(suffix=f".{format}") as temp_file:
                temp_file.write(audio_data)
                temp_file.flush()

                # Load audio using librosa
                audio, sr = librosa.load(temp_file.name, sr=sample_rate)

                # Normalize audio
                audio = librosa.util.normalize(audio)

                # Transcribe using Whisper
                result = await asyncio.get_event_loop().run_in_executor(
                    None,
                    lambda: self.whisper_model.transcribe(
                        audio, language=language, task="transcribe"
                    ),
                )

                processing_time = time.time() - start_time

                return {
                    "text": result["text"].strip(),
                    "language": result.get("language", "unknown"),
                    "confidence": self._calculate_confidence(result),
                    "segments": result.get("segments", []),
                    "processing_time": processing_time,
                    "audio_duration": len(audio) / sr,
                }

        except Exception as e:
            logger.error(f"Speech-to-text failed: {str(e)}")
            raise

    async def text_to_speech(
        self,
        text: str,
        voice_id: str = "default",
        format: str = "mp3",
        model_id: str = "eleven_multilingual_v2",
    ) -> Dict[str, Any]:
        """Convert text to speech using ElevenLabs"""
        start_time = time.time()

        try:
            if not self.elevenlabs_client:
                raise RuntimeError("ElevenLabs client not initialized")

            # Get voice configuration
            voice_config = self.voice_configs.get(
                voice_id, self.voice_configs["default"]
            )

            # Generate speech
            response = self.elevenlabs_client.text_to_speech.convert(
                voice_id=voice_config["voice_id"],
                text=text,
                model_id=model_id,
                voice_settings=voice_config["settings"],
            )

            # Collect audio data
            audio_data = b""
            for chunk in response:
                audio_data += chunk

            # Encode to base64
            audio_base64 = base64.b64encode(audio_data).decode("utf-8")

            processing_time = time.time() - start_time

            return {
                "audio_data": audio_base64,
                "format": format,
                "voice_used": voice_config["name"],
                "voice_id": voice_config["voice_id"],
                "text_length": len(text),
                "audio_size": len(audio_data),
                "processing_time": processing_time,
                "estimated_duration": len(text) / 200 * 60,  # Rough estimate
            }

        except Exception as e:
            logger.error(f"Text-to-speech failed: {str(e)}")
            raise

    async def voice_synthesis(
        self,
        text: str,
        voice_settings: Dict[str, Any] = None,
        custom_voice_id: Optional[str] = None,
    ) -> Dict[str, Any]:
        """Advanced voice synthesis with custom settings"""
        try:
            voice_settings = voice_settings or {}

            # Create custom voice settings
            custom_settings = VoiceSettings(
                stability=voice_settings.get("stability", 0.5),
                similarity_boost=voice_settings.get("similarity_boost", 0.5),
                style=voice_settings.get("style", 0.0),
                use_speaker_boost=voice_settings.get("use_speaker_boost", True),
            )

            # Use custom voice ID or default
            voice_id = custom_voice_id or self.voice_configs["default"]["voice_id"]

            response = self.elevenlabs_client.text_to_speech.convert(
                voice_id=voice_id,
                text=text,
                model_id="eleven_multilingual_v2",
                voice_settings=custom_settings,
            )

            # Collect audio data
            audio_data = b""
            for chunk in response:
                audio_data += chunk

            # Encode to base64
            audio_base64 = base64.b64encode(audio_data).decode("utf-8")

            return {
                "audio_data": audio_base64,
                "voice_settings": voice_settings,
                "voice_id": voice_id,
                "audio_size": len(audio_data),
            }

        except Exception as e:
            logger.error(f"Voice synthesis failed: {str(e)}")
            raise

    async def process_audio(
        self, audio_data: bytes, operations: List[str] = None
    ) -> Dict[str, Any]:
        """Process audio with various operations"""
        try:
            operations = operations or ["normalize"]

            # Create temporary file
            with tempfile.NamedTemporaryFile(suffix=".wav") as temp_file:
                temp_file.write(audio_data)
                temp_file.flush()

                # Load audio
                audio, sr = librosa.load(temp_file.name)

                # Apply operations
                processed_audio = audio

                for operation in operations:
                    if operation == "normalize":
                        processed_audio = librosa.util.normalize(processed_audio)
                    elif operation == "denoise":
                        processed_audio = self._denoise_audio(processed_audio, sr)
                    elif operation == "amplify":
                        processed_audio = processed_audio * 1.5
                    elif operation == "trim_silence":
                        processed_audio, _ = librosa.effects.trim(processed_audio)

                # Save processed audio
                with tempfile.NamedTemporaryFile(suffix=".wav") as output_file:
                    sf.write(output_file.name, processed_audio, sr)
                    output_file.seek(0)

                    processed_data = output_file.read()
                    processed_base64 = base64.b64encode(processed_data).decode("utf-8")

                return {
                    "processed_audio": processed_base64,
                    "operations_applied": operations,
                    "original_size": len(audio_data),
                    "processed_size": len(processed_data),
                    "sample_rate": sr,
                    "duration": len(processed_audio) / sr,
                }

        except Exception as e:
            logger.error(f"Audio processing failed: {str(e)}")
            raise

    async def get_available_voices(self) -> Dict[str, Any]:
        """Get available voices from ElevenLabs"""
        try:
            if not self.elevenlabs_client:
                return {"voices": list(self.voice_configs.keys()), "source": "local"}

            # Get voices from ElevenLabs
            voices_response = self.elevenlabs_client.voices.get_all()

            available_voices = []
            for voice in voices_response.voices:
                available_voices.append(
                    {
                        "voice_id": voice.voice_id,
                        "name": voice.name,
                        "category": voice.category,
                        "description": voice.description,
                        "preview_url": voice.preview_url,
                        "available_for_tiers": voice.available_for_tiers,
                    }
                )

            return {
                "voices": available_voices,
                "local_voices": list(self.voice_configs.keys()),
                "source": "elevenlabs",
            }

        except Exception as e:
            logger.error(f"Failed to get available voices: {str(e)}")
            return {"voices": list(self.voice_configs.keys()), "source": "local"}

    async def _initialize_whisper_model(self):
        """Initialize Whisper model for speech recognition"""
        try:
            logger.info(f"Loading Whisper model: {self.whisper_model_name}")

            # Load model in executor to avoid blocking
            self.whisper_model = await asyncio.get_event_loop().run_in_executor(
                None, lambda: whisper.load_model(self.whisper_model_name)
            )

            logger.info("Whisper model loaded successfully")

        except Exception as e:
            logger.error(f"Failed to load Whisper model: {str(e)}")
            raise

    async def _test_voice_processing(self):
        """Test voice processing capabilities"""
        try:
            # Test text-to-speech if ElevenLabs is available
            if self.elevenlabs_client:
                test_text = "This is a test of the voice processing system."

                result = await self.text_to_speech(text=test_text, voice_id="default")

                if result and "audio_data" in result:
                    logger.info("Text-to-speech test passed")
                else:
                    logger.warning("Text-to-speech test returned no audio data")

            # Test speech-to-text if Whisper is available
            if self.whisper_model:
                logger.info("Whisper model ready for speech-to-text")

        except Exception as e:
            logger.error(f"Voice processing test failed: {str(e)}")
            # Don't raise - allow server to start with limited functionality

    def _calculate_confidence(self, whisper_result: Dict) -> float:
        """Calculate confidence score from Whisper result"""
        if "segments" not in whisper_result:
            return 0.5

        segments = whisper_result["segments"]
        if not segments:
            return 0.5

        # Average the confidence scores from segments
        total_confidence = sum(segment.get("avg_logprob", 0) for segment in segments)
        avg_confidence = total_confidence / len(segments)

        # Convert log probability to confidence (rough approximation)
        confidence = max(0.0, min(1.0, (avg_confidence + 5) / 5))

        return confidence

    def _denoise_audio(self, audio: np.ndarray, sample_rate: int) -> np.ndarray:
        """Apply basic noise reduction to audio"""
        # Simple spectral subtraction for noise reduction
        # This is a basic implementation - more sophisticated methods exist

        # Compute short-time Fourier transform
        stft = librosa.stft(audio)
        magnitude = np.abs(stft)
        phase = np.angle(stft)

        # Estimate noise from first few frames
        noise_estimate = np.mean(magnitude[:, :10], axis=1, keepdims=True)

        # Spectral subtraction
        alpha = 2.0  # Over-subtraction factor
        clean_magnitude = magnitude - alpha * noise_estimate

        # Ensure magnitude is non-negative
        clean_magnitude = np.maximum(clean_magnitude, 0.1 * magnitude)

        # Reconstruct audio
        clean_stft = clean_magnitude * np.exp(1j * phase)
        clean_audio = librosa.istft(clean_stft)

        return clean_audio

    def get_voice_configs(self) -> Dict[str, Any]:
        """Get available voice configurations"""
        return {
            name: {
                "name": config["name"],
                "description": config["description"],
                "voice_id": config["voice_id"],
            }
            for name, config in self.voice_configs.items()
        }

    async def get_server_status(self) -> Dict[str, Any]:
        """Get current server status"""
        elevenlabs_configured = bool(self.elevenlabs_api_key and self.elevenlabs_client)
        whisper_loaded = bool(self.whisper_model)

        return {
            "name": self.server_name,
            "status": "running" if self.is_running else "stopped",
            "capabilities": self.capabilities,
            "elevenlabs_configured": elevenlabs_configured,
            "whisper_model": self.whisper_model_name if whisper_loaded else None,
            "available_voices": len(self.voice_configs),
            "audio_settings": self.audio_settings,
            "last_ping": time.time(),
        }
