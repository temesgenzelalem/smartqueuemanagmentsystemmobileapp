<?php

namespace App\Services;

use App\Models\User;
use Illuminate\Support\Facades\Http;

class ResendMailer
{
    protected string $apiKey;

    public function __construct()
    {
        $this->apiKey = (string) (config('services.resend.key') ?? env('RESEND_API_KEY', ''));
    }

    public function sendVerification(User $user, string $url): void
    {
        if (empty($this->apiKey)) {
            throw new \RuntimeException('Resend API key not configured');
        }

        $senderEmail = env('RESEND_FROM_ADDRESS', config('mail.from.address') ?? env('MAIL_FROM_ADDRESS'));
        $senderName = env('RESEND_FROM_NAME', config('mail.from.name') ?? env('MAIL_FROM_NAME', 'Tsehay Bank'));
        $from = $senderName ? "{$senderName} <{$senderEmail}>" : $senderEmail;
        $name = htmlspecialchars($user->name ?? $user->email, ENT_QUOTES, 'UTF-8');
        $verificationUrl = htmlspecialchars($url, ENT_QUOTES, 'UTF-8');

        $payload = [
            'from' => $from,
            'to' => [$user->email],
            'subject' => 'Verify your email address',
            'html' => "<p>Hello {$name},</p><p>Please verify your email by clicking <a href=\"{$verificationUrl}\">this link</a>.</p>",
            'text' => "Hello ".($user->name ?? $user->email)."\nPlease verify your email by opening this link: {$url}",
        ];

        $response = Http::timeout((int) env('MAIL_HTTP_TIMEOUT', 10))
            ->withToken($this->apiKey)
            ->acceptJson()
            ->post('https://api.resend.com/emails', $payload);

        if (!$response->successful()) {
            $body = $response->body();
            $decoded = null;
            try {
                $decoded = json_decode($body, true);
            } catch (\Throwable $_) {
                // ignore
            }
            $msg = $decoded['message'] ?? $body;
            throw new \RuntimeException('Resend API error (status '.$response->status().'): '.$msg);
        }
    }
}
