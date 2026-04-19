<?php

namespace App\Http\Controllers;

use App\Models\Transaction;
use App\Models\User;
use App\Models\Window;
use App\Models\Setting;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\DB;

class AdminController extends Controller
{
    public function getSettings()
    {
        return response()->json([
            'withdraw_min' => (float) Setting::get('withdraw_min', 100),
            'withdraw_max' => (float) Setting::get('withdraw_max', 50000),
        ]);
    }

    public function saveSettings(Request $request)
    {
        $request->validate([
            'withdraw_min' => 'required|numeric|min:1',
            'withdraw_max' => 'required|numeric|gt:withdraw_min',
        ]);
        Setting::set('withdraw_min', $request->withdraw_min);
        Setting::set('withdraw_max', $request->withdraw_max);
        return response()->json(['message' => 'Settings saved']);
    }

    public function liveQueue()
    {
        $windows = Window::with(['accountant', 'transactions' => function($q) {
            $q->with('user')
              ->whereIn('status', ['waiting', 'pending', 'processing'])
              ->orderBy('created_at', 'asc');
        }])->get();

        return response()->json($windows);
    }

    public function createAccountant(Request $request)
    {
        $request->validate([
            'name'     => 'required|string',
            'email'    => 'required|email|unique:users',
            'password' => 'required|min:6',
            'window'   => 'nullable|string',
        ]);

        $user = User::create([
            'name'     => $request->name,
            'email'    => $request->email,
            'password' => Hash::make($request->password),
            'role'     => 'accountant',
        ]);

        if ($request->window) {
            Window::create(['name' => $request->window, 'accountant_id' => $user->id]);
        }

        return response()->json(['message' => 'Accountant created', 'user' => $user], 201);
    }

    public function listAccountants()
    {
        $accountants = User::where('role', 'accountant')
            ->with('window')
            ->get();
        return response()->json($accountants);
    }

    public function deleteAccountant($id)
    {
        $user = User::findOrFail($id);
        Window::where('accountant_id', $id)->delete();
        $user->delete();
        return response()->json(['message' => 'Accountant deleted']);
    }

    public function updateProfile(Request $request)
    {
        $user = $request->user();
        if ($request->name) $user->name = $request->name;
        if ($request->password) $user->password = Hash::make($request->password);
        $user->save();
        return response()->json(['message' => 'Profile updated', 'user' => $user]);
    }

    public function transactions(Request $request, $period)
    {
        $query = Transaction::query();

        if ($period === 'daily')   $query->whereDate('created_at', today());
        elseif ($period === 'weekly')  $query->whereBetween('created_at', [now()->startOfWeek(), now()->endOfWeek()]);
        elseif ($period === 'monthly') $query->whereMonth('created_at', now()->month)->whereYear('created_at', now()->year);
        elseif ($period === 'yearly')  $query->whereYear('created_at', now()->year);

        if ($request->type && $request->type !== 'all') {
            $query->where('type', $request->type);
        }

        $data   = $query->get();
        $totals = [
            'deposit'  => (clone $query)->where('type', 'deposit')->sum('amount'),
            'withdraw' => (clone $query)->where('type', 'withdraw')->sum('amount'),
            'transfer' => (clone $query)->where('type', 'transfer')->sum('amount'),
            'count'    => $data->count(),
        ];

        return response()->json(['transactions' => $data, 'totals' => $totals]);
    }

    public function listWindows()
    {
        return response()->json(Window::with('accountant')->get());
    }

    public function createWindow(Request $request)
    {
        $request->validate(['name' => 'required|string']);
        $window = Window::create(['name' => $request->name, 'accountant_id' => $request->accountant_id]);
        return response()->json(['message' => 'Window created', 'window' => $window], 201);
    }

    public function deleteWindow($id)
    {
        Window::findOrFail($id)->delete();
        return response()->json(['message' => 'Window deleted']);
    }
}
