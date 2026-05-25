<?php

namespace App\Providers;

use Illuminate\Auth\Notifications\ResetPassword;
use Illuminate\Auth\Notifications\VerifyEmail;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        if (app()->environment('production')) {
            \URL::forceScheme('https');
        }

        ResetPassword::createUrlUsing(function (object $notifiable, string $token) {
            return config('app.frontend_url')."/password-reset/$token?email={$notifiable->getEmailForPasswordReset()}";
        });

        VerifyEmail::createUrlUsing(function (object $notifiable) {
            // In non-production (local/dev), point verification links to the backend
            // so clicks work without a deployed frontend. In production, point
            // to the frontend app as usual.
            if (!app()->environment('production')) {
                return config('app.url')."/api/email/verify/{$notifiable->getKey()}/".sha1($notifiable->getEmailForVerification());
            }

            return config('app.frontend_url')."/customer/verify?id={$notifiable->getKey()}&hash=".sha1($notifiable->getEmailForVerification());
        });
    }
}
