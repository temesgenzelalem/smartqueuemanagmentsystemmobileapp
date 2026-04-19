<?php

namespace App\Http\Controllers;

use App\Models\Transaction;
use App\Models\Setting;
use App\Models\Window;
use Illuminate\Http\Request;

class CustomerController extends Controller
{
    public function store(Request $request)
    {
        $request->validate([
            'type'           => 'required|in:deposit,withdraw,transfer',
            'window_id'      => 'required|exists:windows,id',
            'account_number' => 'required|regex:/^[0-9]+$/|max:20',
            'account_holder' => 'required|regex:/^[a-zA-Z\s]+$/|max:100',
            'amount'         => 'required|numeric|min:1',
            'amount_words'   => 'required|regex:/^[a-zA-Z\s]+$/|max:200',
            'deposited_by'   => 'nullable|string',
            'date'           => 'nullable|date',
            'to_account'     => 'nullable|string',
            'photo'          => 'required|image|max:4096',
            'signature'      => 'required|image|max:2048',
        ], [
            'account_number.regex' => 'Account number must contain only numbers.',
            'account_holder.regex' => 'Account holder name must contain only letters and spaces.',
            'amount_words.regex' => 'Amount in words must contain only letters and spaces.',
        ]);

        // Enforce withdrawal limits
        if ($request->type === 'withdraw') {
            $min = (float) Setting::get('withdraw_min', 100);
            $max = (float) Setting::get('withdraw_max', 50000);
            if ($request->amount < $min) {
                return response()->json(['message' => "Minimum withdrawal is {$min} ETB"], 422);
            }
            if ($request->amount > $max) {
                return response()->json(['message' => "Maximum withdrawal is {$max} ETB"], 422);
            }
        }

        $photoPath   = $request->file('photo')->store('transactions', 'public');
        $signaturePath = $request->file('signature')->store('signatures', 'public');
        $lastQueue   = Transaction::whereDate('created_at', today())->max('queue_number');
        $nextNum     = $lastQueue ? (intval(substr($lastQueue, 1)) + 1) : 1;
        $queueNumber = 'Q' . str_pad($nextNum, 3, '0', STR_PAD_LEFT);

        $transaction = Transaction::create([
            'user_id'        => auth()->id(),
            'type'           => $request->type,
            'window_id'      => $request->window_id,
            'queue_number'   => $queueNumber,
            'account_number' => $request->account_number,
            'account_holder' => $request->account_holder,
            'amount'         => $request->amount,
            'amount_words'   => $request->amount_words,
            'deposited_by'   => $request->deposited_by,
            'date'           => $request->date,
            'to_account'     => $request->to_account,
            'photo'          => $photoPath,
            'signature'      => $signaturePath,
            'status'         => 'waiting',
        ]);

        return response()->json(['message' => 'Submitted to queue', 'data' => $transaction], 201);
    }

    public function status(Request $request)
    {
        $transactions = Transaction::with('receipt')
            ->where('user_id', auth()->id())
            ->orderBy('created_at', 'desc')
            ->get()
            ->map(function ($t) {
                if ($t->receipt) {
                    $t->receipt_url = asset('storage/' . $t->receipt->image_path);
                }
                if ($t->signature) {
                    $t->signature_url = asset('storage/' . $t->signature);
                }
                return $t;
            });

        return response()->json($transactions);
    }

    // Returns windows with queue count + estimated wait time
    public function windowsInfo()
    {
        $windows = Window::withCount(['transactions as waiting_count' => function ($q) {
            $q->where('status', 'waiting');
        }])->get()->map(function ($w) {
            $w->estimated_minutes = $w->waiting_count * 4;
            return $w;
        });

        return response()->json($windows);
    }
}
