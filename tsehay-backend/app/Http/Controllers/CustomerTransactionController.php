<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;

class CustomerTransactionController extends Controller
{
    public function deposit(Request $request)
    {
        $request->validate(['amount' => 'required|numeric|min:1']);

        return response()->json(['message' => 'Deposit request submitted', 'amount' => $request->amount]);
    }

    public function withdraw(Request $request)
    {
        $request->validate(['amount' => 'required|numeric|min:1']);

        return response()->json(['message' => 'Withdraw request submitted', 'amount' => $request->amount]);
    }

    public function transfer(Request $request)
    {
        $request->validate([
            'to_account' => 'required|string',
            'amount' => 'required|numeric|min:1',
        ]);

        return response()->json(['message' => 'Transfer request submitted', 'amount' => $request->amount]);
    }
}
