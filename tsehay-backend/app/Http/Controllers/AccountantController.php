<?php

namespace App\Http\Controllers;

use App\Models\Transaction;
use App\Models\Window;
use Illuminate\Http\Request;

class AccountantController extends Controller
{
    private function myWindowId()
    {
        $window = Window::where('accountant_id', auth()->id())->first();
        return $window?->id;
    }

    public function queue()
    {
        $windowId = $this->myWindowId();

        $transactions = Transaction::with('user')
            ->where('window_id', $windowId)
            ->whereIn('status', ['waiting', 'pending', 'processing'])
            ->orderBy('created_at', 'asc')
            ->get()
            ->map(function ($t) {
                $t->photo_url = $t->photo ? asset('storage/' . $t->photo) : null;
                $t->signature_url = $t->signature ? asset('storage/' . $t->signature) : null;
                return $t;
            });

        return response()->json($transactions);
    }

    public function callNext(Request $request)
    {
        $windowId = $this->myWindowId();

        $transaction = Transaction::where('status', 'waiting')
            ->where('window_id', $windowId)
            ->orderBy('created_at', 'asc')
            ->first();

        if (!$transaction) {
            return response()->json(['message' => 'No customers in queue'], 404);
        }

        $transaction->update(['status' => 'called']);

        return response()->json(['message' => 'Customer called', 'data' => $transaction]);
    }

    public function select($id)
    {
        $windowId = $this->myWindowId();
        $transaction = Transaction::with('user')
            ->where('id', $id)
            ->where('window_id', $windowId)
            ->firstOrFail();

        $transaction->update(['status' => 'pending']);
        $transaction->photo_url = $transaction->photo ? asset('storage/' . $transaction->photo) : null;
        return response()->json($transaction);
    }

    public function process($id)
    {
        $transaction = Transaction::findOrFail($id);
        $transaction->update(['status' => 'processing']);
        return response()->json(['message' => 'Transaction processing']);
    }

    public function complete($id)
    {
        $transaction = Transaction::findOrFail($id);
        $transaction->update(['status' => 'completed']);
        return response()->json(['message' => 'Transaction completed']);
    }

    public function current()
    {
        $windowId = $this->myWindowId();

        $transaction = Transaction::with('user')
            ->where('window_id', $windowId)
            ->whereIn('status', ['pending', 'processing'])
            ->latest()
            ->first();

        if (!$transaction) {
            return response()->json(null);
        }

        $transaction->photo_url = $transaction->photo ? asset('storage/' . $transaction->photo) : null;
        return response()->json($transaction);
    }
}
