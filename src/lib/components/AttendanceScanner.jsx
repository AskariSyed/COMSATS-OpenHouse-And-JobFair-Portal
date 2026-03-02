import React, { useEffect, useRef, useState } from 'react';
import { Camera, Loader2, ChevronLeft, CheckCircle2 } from 'lucide-react';
import { markAttendanceByQr } from '../api';
import jsQR from 'jsqr';

export default function AttendanceScanner({ onBack, onError, onMarked }) {
  const videoRef = useRef(null);
  const streamRef = useRef(null);
  const canvasRef = useRef(null);
  const scanningRef = useRef(false);

  const [manualToken, setManualToken] = useState('');
  const [cameraStatus, setCameraStatus] = useState('Initializing camera...');
  const [submitting, setSubmitting] = useState(false);
  const [marked, setMarked] = useState(false);

  const stopStream = () => {
    if (streamRef.current) {
      streamRef.current.getTracks().forEach((track) => track.stop());
      streamRef.current = null;
    }
  };

  const handleMark = async (token) => {
    if (!token || submitting || marked) return;

    setSubmitting(true);
    try {
      await markAttendanceByQr(token);
      setMarked(true);
      setCameraStatus('Attendance marked successfully.');
      stopStream();
      if (onMarked) onMarked();
    } catch (err) {
      onError(err.message || 'Failed to mark attendance');
      setCameraStatus('QR not valid. Try again.');
      scanningRef.current = false;
    } finally {
      setSubmitting(false);
    }
  };

  useEffect(() => {
    let rafId;

    const startCamera = async () => {
      try {
        if (typeof window === 'undefined' || typeof navigator === 'undefined') {
          setCameraStatus('Browser camera APIs are unavailable.');
          return;
        }

        if (!window.isSecureContext) {
          setCameraStatus('Camera requires HTTPS (or localhost). Use manual token input.');
          return;
        }

        if (!navigator.mediaDevices?.getUserMedia) {
          setCameraStatus('Camera API not supported. Use manual token input.');
          return;
        }

        let stream;
        try {
          stream = await navigator.mediaDevices.getUserMedia({
            video: {
              facingMode: { ideal: 'environment' },
              width: { ideal: 1280 },
              height: { ideal: 720 }
            }
          });
        } catch {
          stream = await navigator.mediaDevices.getUserMedia({ video: true });
        }

        streamRef.current = stream;
        if (videoRef.current) {
          videoRef.current.srcObject = stream;
          await videoRef.current.play().catch(() => {});
        }
        setCameraStatus('Camera ready. Point to today\'s attendance QR.');

        const scanFrame = async () => {
          if (scanningRef.current || submitting || marked || !videoRef.current || !canvasRef.current) {
            rafId = requestAnimationFrame(scanFrame);
            return;
          }

          const video = videoRef.current;
          const canvas = canvasRef.current;

          if (video.readyState >= HTMLMediaElement.HAVE_CURRENT_DATA) {
            const width = video.videoWidth;
            const height = video.videoHeight;

            if (width > 0 && height > 0) {
              canvas.width = width;
              canvas.height = height;
              const context = canvas.getContext('2d', { willReadFrequently: true });

              if (context) {
                context.drawImage(video, 0, 0, width, height);
                const imageData = context.getImageData(0, 0, width, height);
                const result = jsQR(imageData.data, width, height, { inversionAttempts: 'attemptBoth' });

                if (result?.data) {
                  scanningRef.current = true;
                  await handleMark(result.data);
                }
              }
            }
          }

          rafId = requestAnimationFrame(scanFrame);
        };

        rafId = requestAnimationFrame(scanFrame);
      } catch (err) {
        setCameraStatus(`Camera access failed: ${err.message || 'Unknown error'}`);
      }
    };

    startCamera();

    return () => {
      if (rafId) cancelAnimationFrame(rafId);
      stopStream();
    };
  }, [marked, submitting]);

  return (
    <div className="max-w-3xl mx-auto py-6">
      <div className="bg-white border border-gray-200 rounded-xl shadow-sm p-4 space-y-4">
        <div className="flex items-center justify-between">
          <button
            onClick={onBack}
            className="inline-flex items-center gap-1.5 text-sm text-gray-600 hover:text-gray-900"
          >
            <ChevronLeft className="w-4 h-4" /> Back
          </button>
          <h2 className="text-lg font-bold text-gray-900">Mark Attendance</h2>
          <div className="w-14" />
        </div>

        <div className="rounded-lg border border-gray-200 overflow-hidden bg-black/90 aspect-video flex items-center justify-center">
          <video ref={videoRef} autoPlay playsInline muted className="w-full h-full object-cover" />
        </div>
        <canvas ref={canvasRef} className="hidden" />

        <div className="text-sm text-center text-gray-600 flex items-center justify-center gap-2">
          {submitting ? <Loader2 className="w-4 h-4 animate-spin" /> : <Camera className="w-4 h-4" />}
          {cameraStatus}
        </div>

        <div className="border-t border-gray-100 pt-3 space-y-2">
          <p className="text-xs text-gray-500 text-center">If scan doesn't work, paste token manually</p>
          <div className="flex gap-2">
            <input
              value={manualToken}
              onChange={(e) => setManualToken(e.target.value)}
              placeholder="Paste attendance token"
              className="flex-1 border border-gray-300 rounded px-3 py-2 text-sm"
            />
            <button
              type="button"
              disabled={!manualToken.trim() || submitting || marked}
              onClick={() => handleMark(manualToken.trim())}
              className="px-4 py-2 bg-blue-600 text-white rounded text-sm font-medium hover:bg-blue-700 disabled:opacity-50"
            >
              Verify
            </button>
          </div>
        </div>

        {marked && (
          <div className="flex items-center justify-center gap-2 text-green-700 bg-green-50 border border-green-200 rounded p-2 text-sm">
            <CheckCircle2 className="w-4 h-4" /> Attendance marked successfully
          </div>
        )}
      </div>
    </div>
  );
}
