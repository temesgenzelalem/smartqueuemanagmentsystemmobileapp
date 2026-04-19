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
        if ($this->role === 'customer') {
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
