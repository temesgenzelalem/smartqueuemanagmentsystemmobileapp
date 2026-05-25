<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use App\Models\User;

class BrevoMailer
{
    protected string $apiKey;

    public function __construct()
    {
        $this->apiKey = config('services.brevo.api_key') ?? env('BREVO_API_KEY');
    }

    public function sendVerification(User $user, string $url): void
    {
        if (empty($this->apiKey)) {
            throw new \RuntimeException('Brevo API key not configured');
        }

        $senderEmail = config('mail.from.address') ?? env('MAIL_FROM_ADDRESS');
        $senderName = config('mail.from.name') ?? env('MAIL_FROM_NAME', 'Tsehay Bank');

        $payload = [
            'sender' => ['name' => $senderName, 'email' => $senderEmail],
            'to' => [[ 'email' => $user->email, 'name' => $user->name ?? $user->email ]],
            'subject' => 'Verify your email address',
            'htmlContent' => "<p>Hello {$user->name},</p><p>Please verify your email by clicking <a href=\"{$url}\">this link</a>.</p>",
            'textContent' => "Hello {$user->name}\nPlease verify your email by opening this link: {$url}",
        ];

        $response = Http::withHeaders([
            'accept' => 'application/json',
            'api-key' => $this->apiKey,
            'content-type' => 'application/json',
        ])->post('https://api.brevo.com/v3/smtp/email', $payload);

        if (!$response->successful()) {
            $body = $response->body();
            $decoded = null;
            try {
                $decoded = json_decode($body, true);
            } catch (\Throwable $_) {
                // ignore
            }
            $msg = $decoded['message'] ?? $body;
            throw new \RuntimeException('Brevo API error (status '.$response->status().'): '.$msg);
        }
    }
}
