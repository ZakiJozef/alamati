<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class UploadController extends Controller
{
    /**
     * Upload a profile picture.
     */
    public function profilePic(Request $request)
    {
        try {
            $request->validate([
                'file' => 'required|image|mimes:jpeg,png,jpg,gif,webp|max:5120',
            ]);

            $file = $request->file('file');
            $filename = 'profile_' . auth()->id() . '_' . time() . '.' . $file->getClientOriginalExtension();

            // Store in public disk
            $path = $file->storeAs('profile-pics', $filename, 'public');

            // Build URL using request host
            $scheme = $request->secure() ? 'https' : 'http';
            $host = $request->getHost();
            $port = $request->getPort();
            $portSuffix = ($port && !in_array($port, [80, 443])) ? ':' . $port : '';
            $url = "{$scheme}://{$host}{$portSuffix}/storage/{$path}";

            // Update user's profile pic
            $user = auth()->user();
            if (!$user) {
                throw new \Exception('User not found or not authenticated properly.');
            }
            $user->profile_pic = $url;
            $user->save();

            return response()->json([
                'success' => true,
                'url' => $user->profile_pic,
                'message' => 'Profile picture uploaded successfully',
            ]);
        } catch (\Throwable $e) {
            return response()->json([
                'success' => false,
                'message' => 'Upload failed: ' . $e->getMessage(),
                'trace' => $e->getTraceAsString(),
            ], 500);
        }
    }

    /**
     * Generic file upload (for store images, product images, etc.)
     */
    public function store(Request $request)
    {
        $request->validate([
            'file' => 'required|file|mimes:jpeg,png,jpg,gif,webp,pdf|max:10240',
            'folder' => 'nullable|string',
        ]);

        $file = $request->file('file');
        $folder = $request->input('folder', 'uploads');
        $filename = Str::random(20) . '_' . time() . '.' . $file->getClientOriginalExtension();

        $path = $file->storeAs($folder, $filename, 'public');

        // Build URL using request host to ensure mobile devices can access it
        $scheme = $request->secure() ? 'https' : 'http';
        $host = $request->getHost();
        $port = $request->getPort();
        $portSuffix = ($port && !in_array($port, [80, 443])) ? ':' . $port : '';
        $url = "{$scheme}://{$host}{$portSuffix}/storage/{$path}";

        return response()->json([
            'success' => true,
            'url' => $url,
            'path' => $path,
            'message' => 'File uploaded successfully',
        ]);
    }
}
