<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Window extends Model
{
    protected $fillable = ['name', 'accountant_id'];

    public function accountant()
    {
        return $this->belongsTo(User::class, 'accountant_id');
    }

    public function transactions()
    {
        return $this->hasMany(\App\Models\Transaction::class, 'window_id');
    }
}
