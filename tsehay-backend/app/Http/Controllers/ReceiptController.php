<?php

namespace App\Http\Controllers;

use App\Models\Receipt;
use App\Models\Transaction;
use App\Models\Window;
use Illuminate\Http\Request;

class ReceiptController extends Controller
{
    // Accountant sends receipt
    public function send(Request $request, $transactionId)
    {
        $request->validate([
            'image' => 'required|image|mimes:jpg,jpeg,png|max:4096',
        ]);

        $transaction = Transaction::findOrFail($transactionId);

        $path = $request->file('image')->store('receipts', 'public');

        $receipt = Receipt::updateOrCreate(
            ['transaction_id' => $transaction->id],
            [
                'window_id'   => Window::where('accountant_id', auth()->id())->value('id'),
                'customer_id' => $transaction->user_id,
                'image_path'  => $path,
            ]
        );

        return response()->json([
            'message'     => 'Receipt sent successfully',
            'receipt_url' => asset('storage/' . $path),
        ]);
    }

    // Customer views their receipts
    public function myReceipts()
    {
        $receipts = Receipt::with('transaction')
            ->where('customer_id', auth()->id())
            ->latest()
            ->get()
            ->map(function ($r) {
                $r->receipt_url = asset('storage/' . $r->image_path);
                return $r;
            });

        return response()->json($receipts);
    }
}
