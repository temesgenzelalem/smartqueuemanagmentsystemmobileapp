<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\User;
use Illuminate\Support\Facades\Hash;

class AuthController extends Controller
{
    public function register(Request $request)
    {
        $request->validate([
            'name' => 'required|string',
            'email' => 'required|email|unique:users',
            'password' => 'required|min:6',
            'role' => 'sometimes|in:customer,manager,accountant'
        ]);

        $role = $request->role ?? 'customer';

        $user = \App\Models\User::create([
            'name' => $request->name,
            'email' => $request->email,
            'password' => \Illuminate\Support\Facades\Hash::make($request->password),
            'role' => $role,
        ]);

        // Send email verification for customers only
        if ($role === 'customer') {
            $user->sendEmailVerificationNotification();
        } else {
            // Auto-verify managers and accountants
            $user->markEmailAsVerified();
        }

        return response()->json([
            'message' => $role === 'customer'
                ? 'User registered successfully. Please check your email for verification.'
                : 'User registered successfully',
            'user' => $user,
            'requires_verification' => $role === 'customer'
        ]);
    }

    // Login
    public function login(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
            'password' => 'required'
        ]);

        $user = User::where('email', $request->email)->first();

        if (!$user || !Hash::check($request->password, $user->password)) {
            return response()->json([
                'message' => 'Invalid credentials'
            ], 401);
        }

        // Check email verification for customers only
        if ($user->role === 'customer' && !$user->hasVerifiedEmail()) {
            return response()->json([
                'message' => 'Please verify your email address before logging in.',
                'requires_verification' => true,
                'email' => $user->email
            ], 403);
        }

        // Create token (Sanctum)
        $token = $user->createToken('api-token')->plainTextToken;

        return response()->json([
            'user' => $user,
            'token' => $token
        ]);
    }

    // Logout
    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json([
            'message' => 'Logged out'
        ]);
    }

    // Email verification
    public function verifyEmail(Request $request, $id, $hash)
    {
        $user = User::findOrFail($id);

        // Only allow verification for customers
        if ($user->role !== 'customer') {
            return response()->json(['message' => 'Email verification not required for this account type.'], 400);
        }

        if (!hash_equals((string) $id, (string) $user->getKey())) {
            return response()->json(['message' => 'Invalid verification link.'], 400);
        }

        if (!hash_equals($hash, sha1($user->getEmailForVerification()))) {
            return response()->json(['message' => 'Invalid verification link.'], 400);
        }

        if ($user->hasVerifiedEmail()) {
            return response()->json(['message' => 'Email already verified.'], 400);
        }

        $user->markEmailAsVerified();

        return response()->json(['message' => 'Email verified successfully.']);
    }

    // Resend verification email
    public function resendVerification(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
        ]);

        $user = User::where('email', $request->email)->first();

        if (!$user || $user->role !== 'customer') {
            return response()->json(['message' => 'Email verification not required for this account type.'], 400);
        }

        if ($user->hasVerifiedEmail()) {
            return response()->json(['message' => 'Email already verified.'], 400);
        }

        try {
            $user->sendEmailVerificationNotification();
        } catch (\Throwable $e) {
            logger()->error('Email resend failed: '.$e->getMessage());
            return response()->json(['message' => 'Unable to resend verification email. Please try again later.'], 500);
        }

        return response()->json(['message' => 'Verification email sent.']);
    }

    // Dev-only: manually verify a customer's email when email delivery isn't available
    public function manualVerify(Request $request)
    {
        if (config('app.env') === 'production') {
            return response()->json(['message' => 'Manual verification is disabled in production.'], 403);
        }

        $request->validate([
            'email' => 'required|email',
        ]);

        $user = User::where('email', $request->email)->first();

        if (!$user || $user->role !== 'customer') {
            return response()->json(['message' => 'User not found or verification not required for this account type.'], 400);
        }

        if ($user->hasVerifiedEmail()) {
            return response()->json(['message' => 'Email already verified.'], 400);
        }

        $user->markEmailAsVerified();

        return response()->json(['message' => 'Email manually verified.']);
    }
}