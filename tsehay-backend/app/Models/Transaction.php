<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Transaction extends Model
{
    protected $fillable = [
        'user_id', 'type', 'amount', 'account_number', 'account_holder',
        'amount_words', 'deposited_by', 'to_account', 'photo', 'signature', 'date',
        'status', 'window_id', 'priority', 'queue_number',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function receipt()
    {
        return $this->hasOne(Receipt::class);
    }
}
