<?php

namespace App\Models;

// use Illuminate\Contracts\Auth\MustVerifyEmail;
use Database\Factories\UserFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\Hidden;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

#[Fillable(['name', 'email', 'password', 'role'])]
#[Hidden(['password', 'remember_token'])]
class User extends Authenticatable implements \Illuminate\Contracts\Auth\MustVerifyEmail
{
    /** @use HasFactory<UserFactory> */
    use HasApiTokens, HasFactory, Notifiable;

    public function window()
    {
        return $this->hasOne(Window::class, 'accountant_id');
    }

    /**
     * Check if email verification is required for this user
     */
    public function hasVerifiedEmail()
    {
        // Only require email verification for customers
        if ($this->role === 'customer') {
            return !is_null($this->email_verified_at);
        }
        // Managers and accountants are automatically verified
        return true;
    }

    /**
     * Mark email as verified
     */
    public function markEmailAsVerified()
    {
        if ($this->role === 'customer') {
            return parent::markEmailAsVerified();
        }
        return $this;
    }

    /**
     * Send email verification notification
     */
    public function sendEmailVerificationNotification()
    {
        if ($this->role !== 'customer') {
            return;
        }

        // If BREVO_API_KEY is configured, send verification via Brevo HTTP API.
        $brevoKey = config('services.brevo.api_key') ?? env('BREVO_API_KEY');
        if (!$brevoKey) {
            logger()->warning('Brevo API key not configured. Falling back to default mail notification.');
            return parent::sendEmailVerificationNotification();
        }

        // Generate a verification link that opens the frontend verification page
        $frontendUrl = rtrim(env('FRONTEND_URL', config('app.url')), '/');
        $url = $frontendUrl.'/customer/verify?id='.$this->getKey().'&hash='.sha1($this->getEmailForVerification());

        // Send via Brevo service, but fall back to the default notification on error
        try {
            $mailer = new \App\Services\BrevoMailer();
            $mailer->sendVerification($this, $url);
            return;
        } catch (\Throwable $e) {
            logger()->error('Brevo mailer failed: '.$e->getMessage());
            // Fallback to the framework's default mail notification
            return parent::sendEmailVerificationNotification();
        }
    }

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
        ];
    }
}
