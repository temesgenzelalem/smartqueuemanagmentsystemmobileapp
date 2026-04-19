<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AdminController;
use App\Http\Controllers\AccountantController;
use App\Http\Controllers\CustomerController;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\ReceiptController;

// ── Auth ──────────────────────────────────────────────────────────────────────
Route::post('/register', [AuthController::class, 'register']);
Route::post('/login',    [AuthController::class, 'login']);
Route::post('/logout',   [AuthController::class, 'logout'])->middleware('auth:sanctum');

// Email verification routes (for customers only)
Route::get('/email/verify/{id}/{hash}', [AuthController::class, 'verifyEmail'])->name('verification.verify');
Route::post('/email/resend', [AuthController::class, 'resendVerification'])->name('verification.send');

// ── Public (authenticated any role) ──────────────────────────────────────────
Route::middleware('auth:sanctum')->group(function () {
    Route::get('/user',              fn(Request $r) => $r->user());
    Route::get('/available-windows', [CustomerController::class, 'windowsInfo']);
    Route::get('/settings',          [AdminController::class, 'getSettings']);
});

// ── Admin ─────────────────────────────────────────────────────────────────────
Route::middleware(['auth:sanctum', 'role:admin'])->group(function () {
    Route::get('/admin/live-queue',        [AdminController::class, 'liveQueue']);
    Route::put('/admin/profile',           [AdminController::class, 'updateProfile']);
    Route::get('/admin/settings',          [AdminController::class, 'getSettings']);
    Route::post('/admin/settings',         [AdminController::class, 'saveSettings']);
    Route::get('/accountants',             [AdminController::class, 'listAccountants']);
    Route::post('/accountants',            [AdminController::class, 'createAccountant']);
    Route::delete('/accountants/{id}',     [AdminController::class, 'deleteAccountant']);
    Route::get('/windows',                 [AdminController::class, 'listWindows']);
    Route::post('/windows',                [AdminController::class, 'createWindow']);
    Route::delete('/windows/{id}',         [AdminController::class, 'deleteWindow']);
    Route::get('/transactions/{period}',   [AdminController::class, 'transactions']);
});

// ── Accountant ────────────────────────────────────────────────────────────────
Route::middleware(['auth:sanctum', 'role:accountant'])->group(function () {
    Route::get('/queue',                   [AccountantController::class, 'queue']);
    Route::get('/queue/current',           [AccountantController::class, 'current']);
    Route::post('/queue/call-next',        [AccountantController::class, 'callNext']);
    Route::post('/queue/select/{id}',      [AccountantController::class, 'select']);
    Route::post('/queue/process/{id}',     [AccountantController::class, 'process']);
    Route::post('/queue/complete/{id}',    [AccountantController::class, 'complete']);
    Route::post('/receipts/{txId}',        [ReceiptController::class, 'send']);
});

// ── Customer ──────────────────────────────────────────────────────────────────
Route::middleware(['auth:sanctum', 'role:customer'])->group(function () {
    Route::post('/transactions',           [CustomerController::class, 'store']);
    Route::get('/my-transactions',         [CustomerController::class, 'status']);
    Route::get('/my-receipts',             [ReceiptController::class, 'myReceipts']);
});
