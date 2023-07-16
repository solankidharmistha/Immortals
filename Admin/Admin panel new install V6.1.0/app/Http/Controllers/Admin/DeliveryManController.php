<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\DeliveryMan;
use App\Models\DMReview;
use App\Models\Zone;
use App\Models\Conversation;
use App\Models\Message;
use App\Models\UserInfo;
use Brian2694\Toastr\Facades\Toastr;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use App\CentralLogics\Helpers;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Mail;
use Rap2hpoutre\FastExcel\FastExcel;


class DeliveryManController extends Controller
{
    public function index()
    {

        return view('admin-views.delivery-man.index');
    }

    public function list(Request $request)
    {
        $zone_id = $request->query('zone_id', 'all');
        $delivery_men = DeliveryMan::when(is_numeric($zone_id), function($query) use($zone_id){
            return $query->where('zone_id', $zone_id);
        })->with('zone')->where('type','zone_wise')->latest()->where('application_status','approved')->paginate(config('default_pagination'));
        $zone = is_numeric($zone_id)?Zone::findOrFail($zone_id):null;
        return view('admin-views.delivery-man.list', compact('delivery_men', 'zone'));
    }

    public function search(Request $request){
        $key = explode(' ', $request['search']);
        $delivery_men=DeliveryMan::where(function ($q) use ($key) {
            foreach ($key as $value) {
                $q->orWhere('f_name', 'like', "%{$value}%")
                    ->orWhere('l_name', 'like', "%{$value}%")
                    ->orWhere('email', 'like', "%{$value}%")
                    ->orWhere('phone', 'like', "%{$value}%")
                    ->orWhere('identity_number', 'like', "%{$value}%");
            }
        })->where('type','zone_wise')->where('application_status','approved')->get();
        return response()->json([
            'view'=>view('admin-views.delivery-man.partials._table',compact('delivery_men'))->render(),
            'count'=>$delivery_men->count()
        ]);
    }

    public function reviews_list(){
        $reviews=DMReview::with(['delivery_man','customer'])->whereHas('delivery_man',function($query){
            $query->where('type','zone_wise');
        })->latest()->paginate(config('default_pagination'));
        return view('admin-views.delivery-man.reviews-list',compact('reviews'));
    }

    public function preview(Request $request, $id, $tab='info')
    {
        $dm = DeliveryMan::with(['reviews'])->where('type','zone_wise')->where(['id' => $id])->first();
        if($tab == 'info')
        {
            $reviews=DMReview::where(['delivery_man_id'=>$id])->latest()->paginate(config('default_pagination'));
            return view('admin-views.delivery-man.view.info', compact('dm', 'reviews'));
        }
        else if($tab == 'transaction')
        {
            $date = $request->query('date');
            return view('admin-views.delivery-man.view.transaction', compact('dm', 'date'));
        }
        else if($tab == 'timelog')
        {
            $from = $request->query('from', null);
            $to = $request->query('to', null);
            $timelogs = $dm->time_logs()->when($from && $to, function($query)use($from, $to){
                $query->whereBetween('date', [$from, $to]);
            })->paginate(config('default_pagination'));
            return view('admin-views.delivery-man.view.timelog', compact('dm', 'timelogs'));
        }
        else if($tab == 'conversation')
        {
            $user = UserInfo::where(['deliveryman_id' => $id])->first();
            if($user){
                $conversations = Conversation::with(['sender', 'receiver', 'last_message'])->WhereUser($user->id)->paginate(8);
            }else{
                $conversations = [];
            }

            return view('admin-views.delivery-man.view.conversations', compact('conversations','dm'));
        }
    }

    public function store(Request $request)
    {
        $request->validate([
            'f_name' => 'required|max:100',
            'l_name' => 'nullable|max:100',
            'identity_number' => 'required|max:30',
            'email' => 'required|unique:delivery_men',
            'phone' => 'required|regex:/^([0-9\s\-\+\(\)]*)$/|min:10|max:20|unique:delivery_men',
            'zone_id' => 'required',
            'earning' => 'required',
            'password'=>'required|min:6',
            'vehicle_id' => 'required',

        ], [
            'f_name.required' => translate('messages.first_name_is_required'),
            'zone_id.required' => translate('messages.select_a_zone'),
            'vehicle_id.required' => translate('messages.select_a_vehicle'),
            'earning.required' => translate('messages.select_dm_type')
        ]);

        if ($request->has('image')) {
            $image_name = Helpers::upload('delivery-man/', 'png', $request->file('image'));
        } else {
            $image_name = 'def.png';
        }

        $id_img_names = [];
        if (!empty($request->file('identity_image'))) {
            foreach ($request->identity_image as $img) {
                $identity_image = Helpers::upload('delivery-man/', 'png', $img);
                array_push($id_img_names, $identity_image);
            }
            $identity_image = json_encode($id_img_names);
        } else {
            $identity_image = json_encode([]);
        }

        $dm = New DeliveryMan();
        $dm->f_name = $request->f_name;
        $dm->l_name = $request->l_name;
        $dm->email = $request->email;
        $dm->phone = $request->phone;
        $dm->identity_number = $request->identity_number;
        $dm->identity_type = $request->identity_type;
        $dm->zone_id = $request->zone_id;
        $dm->vehicle_id = $request->vehicle_id;
        $dm->identity_image = $identity_image;
        $dm->image = $image_name;
        $dm->active = 0;
        $dm->earning = $request->earning;
        $dm->password = bcrypt($request->password);
        $dm->save();

        Toastr::success(translate('messages.deliveryman_added_successfully'));
        return redirect('admin/delivery-man/list');
    }

    public function edit($id)
    {
        $delivery_man = DeliveryMan::find($id);
        return view('admin-views.delivery-man.edit', compact('delivery_man'));
    }

    public function status(Request $request)
    {
        $delivery_man = DeliveryMan::find($request->id);
        $delivery_man->status = $request->status;

        try
        {
            if($request->status == 0)
            {   $delivery_man->auth_token = null;
                if(isset($delivery_man->fcm_token))
                {
                    $data = [
                        'title' => translate('messages.suspended'),
                        'description' => translate('messages.your_account_has_been_suspended'),
                        'order_id' => '',
                        'image' => '',
                        'type'=> 'block'
                    ];
                    Helpers::send_push_notif_to_device($delivery_man->fcm_token, $data);

                    DB::table('user_notifications')->insert([
                        'data'=> json_encode($data),
                        'delivery_man_id'=>$delivery_man->id,
                        'created_at'=>now(),
                        'updated_at'=>now()
                    ]);
                }

            }

        }
        catch (\Exception $e) {
            Toastr::warning(translate('messages.push_notification_faild'));
        }

        $delivery_man->save();

        Toastr::success(translate('messages.deliveryman_status_updated'));
        return back();
    }

    public function reviews_status(Request $request)
    {
        $review = DMReview::find($request->id);
        $review->status = $request->status;
        $review->save();
        Toastr::success(translate('messages.review_visibility_updated'));
        return back();
    }

    public function earning(Request $request)
    {
        $delivery_man = DeliveryMan::find($request->id);
        $delivery_man->earning = $request->status;

        $delivery_man->save();

        Toastr::success(translate('messages.deliveryman_type_updated'));
        return back();
    }

    public function update_application(Request $request)
    {
        $delivery_man = DeliveryMan::findOrFail($request->id);
        $delivery_man->application_status = $request->status;
        if($request->status == 'approved') $delivery_man->status = 1;
        $delivery_man->save();

        try{
            if( config('mail.status')) {
                Mail::to($request['email'])->send(new \App\Mail\SelfRegistration($request->status, $delivery_man->f_name.' '.$delivery_man->l_name));
            }

        }catch(\Exception $ex){
            info($ex);
        }


        Toastr::success(translate('messages.application_status_updated_successfully'));
        return back();
    }

    public function update(Request $request, $id)
    {
        $request->validate([
            'f_name' => 'required|max:100',
            'l_name' => 'nullable|max:100',
            'identity_number' => 'required|max:30',
            'email' => 'required|unique:delivery_men,email,'.$id,
            'phone' => 'required|regex:/^([0-9\s\-\+\(\)]*)$/|min:10|unique:delivery_men,phone,'.$id,
            'vehicle_id' => 'required',
            'earning' => 'required',
            'password' => 'nullable|min:6',
        ], [
            'f_name.required' => translate('messages.first_name_is_required'),
            'earning.required' => translate('messages.select_dm_type'),
            'vehicle_id.required' => translate('messages.select_a_vehicle'),

        ]);

        $delivery_man = DeliveryMan::find($id);

        if ($request->has('image')) {
            $image_name = Helpers::update('delivery-man/', $delivery_man->image, 'png', $request->file('image'));
        } else {
            $image_name = $delivery_man['image'];
        }

        if ($request->has('identity_image')){
            foreach (json_decode($delivery_man['identity_image'], true) as $img) {
                if (Storage::disk('public')->exists('delivery-man/' . $img)) {
                    Storage::disk('public')->delete('delivery-man/' . $img);
                }
            }
            $img_keeper = [];
            foreach ($request->identity_image as $img) {
                $identity_image = Helpers::upload('delivery-man/', 'png', $img);
                array_push($img_keeper, $identity_image);
            }
            $identity_image = json_encode($img_keeper);
        } else {
            $identity_image = $delivery_man['identity_image'];
        }

        $delivery_man->vehicle_id = $request->vehicle_id;

        $delivery_man->f_name = $request->f_name;
        $delivery_man->l_name = $request->l_name;
        $delivery_man->email = $request->email;
        $delivery_man->phone = $request->phone;
        $delivery_man->identity_number = $request->identity_number;
        $delivery_man->identity_type = $request->identity_type;
        $delivery_man->zone_id = $request->zone_id;
        $delivery_man->identity_image = $identity_image;
        $delivery_man->image = $image_name;
        $delivery_man->earning = $request->earning;
        $delivery_man->password = strlen($request->password)>1?bcrypt($request->password):$delivery_man['password'];
        $delivery_man->save();
        Toastr::success(translate('messages.deliveryman_updated_successfully'));
        return redirect('admin/delivery-man/list');
    }

    public function delete(Request $request)
    {
        $delivery_man = DeliveryMan::find($request->id);
        if (Storage::disk('public')->exists('delivery-man/' . $delivery_man['image'])) {
            Storage::disk('public')->delete('delivery-man/' . $delivery_man['image']);
        }

        foreach (json_decode($delivery_man['identity_image'], true) as $img) {
            if (Storage::disk('public')->exists('delivery-man/' . $img)) {
                Storage::disk('public')->delete('delivery-man/' . $img);
            }
        }
        if($delivery_man->userinfo){

            $delivery_man->userinfo->delete();
        }
        $delivery_man->delete();
        Toastr::success(translate('messages.deliveryman_deleted_successfully'));
        return back();
    }

    public function get_deliverymen(Request $request){
        $key = explode(' ', $request->q);
        $zone_ids = isset($request->zone_ids)?(count($request->zone_ids)>0?$request->zone_ids:[]):0;
        $data=DeliveryMan::when($zone_ids, function($query) use($zone_ids){
            return $query->whereIn('zone_id', $zone_ids);
        })
        ->when($request->earning, function($query){
            return $query->earning();
        })
        ->where(function ($q) use ($key) {
            foreach ($key as $value) {
                $q->orWhere('f_name', 'like', "%{$value}%")
                    ->orWhere('l_name', 'like', "%{$value}%")
                    ->orWhere('email', 'like', "%{$value}%")
                    ->orWhere('phone', 'like', "%{$value}%")
                    ->orWhere('identity_number', 'like', "%{$value}%");
            }
        })->active()->limit(8)->get(['id',DB::raw('CONCAT(f_name, " ", l_name) as text')]);
        return response()->json($data);
    }

    public function get_account_data(DeliveryMan $deliveryman)
    {
        $wallet = $deliveryman->wallet;
        $cash_in_hand = 0;
        $balance = 0;

        if($wallet)
        {
            $cash_in_hand = $wallet->collected_cash;
            $balance = round($wallet->total_earning - $wallet->total_withdrawn - $wallet->pending_withdraw, config('round_up_to_digit'));
        }
        return response()->json(['cash_in_hand'=>$cash_in_hand, 'earning_balance'=>$balance], 200);

    }

    public function get_conversation_list(Request $request)
    {
        $user = UserInfo::where(['deliveryman_id' => $request->user_id])->first();
        $dm = DeliveryMan::find($request->user_id);
        if($user){
            $conversations = Conversation::with(['sender', 'receiver', 'last_message'])->WhereUser($user->id);
            if($request->query('key')) {
                $key = explode(' ', $request->get('key'));
                $conversations = $conversations->where(function($qu)use($key){
                    $qu->where(function($q)use($key){
                        $q->where('sender_type','!=', 'delivery_man')->whereHas('sender',function($query)use($key){
                            foreach ($key as $value) {
                                $query->where('f_name', 'like', "%{$value}%")->orWhere('l_name', 'like', "%{$value}%")->orWhere('phone', 'like', "%{$value}%");
                            }
                        });
                    })->orWhere(function($q)use($key){
                        $q->where('receiver_type','!=', 'delivery_man')->whereHas('receiver',function($query)use($key){
                            foreach ($key as $value) {
                                $query->where('f_name', 'like', "%{$value}%")->orWhere('l_name', 'like', "%{$value}%")->orWhere('phone', 'like', "%{$value}%");
                            }
                        });
                    });
                });
            }
            $conversations = $conversations->WhereUserType('delivery_man')->paginate(8);
        }else{
            $conversations = [];
        }

        $view = view('admin-views.delivery-man.partials._conversation_list',compact('conversations','dm'))->render();
        return response()->json(['html'=>$view]);

    }

    public function conversation_view($conversation_id,$user_id)
    {
        $convs = Message::where(['conversation_id' => $conversation_id])->get();
        $conversation = Conversation::find($conversation_id);
        $receiver = UserInfo::find($conversation->receiver_id);
        $sender = UserInfo::find($conversation->sender_id);
        $user = UserInfo::find($user_id);
        return response()->json([
            'view' => view('admin-views.delivery-man.partials._conversations', compact('convs', 'user', 'receiver'))->render()
        ]);
    }
    public function dm_list_export(Request $request){

        $withdraw_request = DeliveryMan::where('type','zone_wise')->orderBy('id','desc')->get();
        if ($request->type == 'excel') {
            return (new FastExcel(Helpers::export_d_man($withdraw_request)))->download('deliveryman_list.xlsx');
        } elseif ($request->type == 'csv') {
            return (new FastExcel(Helpers::export_d_man($withdraw_request)))->download('deliveryman_list.csv');
        }
    }


    public function pending(Request $request)
    {
        $key = explode(' ', $request['search']);
        $zone_id = $request->query('zone_id', 'all');
        $delivery_men = DeliveryMan::when(is_numeric($zone_id), function($query) use($zone_id){
            return $query->where('zone_id', $zone_id);
        })
        ->when(isset($key),function($query)use($key){
            $query->where(function($q)use($key){
                foreach ($key as $value) {
                    $q->orWhere('f_name', 'like', "%{$value}%")
                ->orWhere('l_name', 'like', "%{$value}%")
                ->orWhere('email', 'like', "%{$value}%")
                ->orWhere('phone', 'like', "%{$value}%")
                ->orWhere('identity_number', 'like', "%{$value}%");
                }
            });
        })
        ->with('zone')->where('type','zone_wise')->where('application_status', 'pending')->latest()->paginate(config('default_pagination'));
        $zone = is_numeric($zone_id)?Zone::findOrFail($zone_id):null;
        return view('admin-views.delivery-man.pending_list', compact('delivery_men', 'zone'));


    }
    public function denied(Request $request)
    {
        $key = explode(' ', $request['search']);
        $zone_id = $request->query('zone_id', 'all');
        $delivery_men = DeliveryMan::when(is_numeric($zone_id), function($query) use($zone_id){
            return $query->where('zone_id', $zone_id);
        })
        ->when(isset($key),function($query)use($key){
            $query->where(function($q)use($key){
                foreach ($key as $value) {
                    $q->orWhere('f_name', 'like', "%{$value}%")
                ->orWhere('l_name', 'like', "%{$value}%")
                ->orWhere('email', 'like', "%{$value}%")
                ->orWhere('phone', 'like', "%{$value}%")
                ->orWhere('identity_number', 'like', "%{$value}%");
                }
            });
        })
        ->with('zone')->where('type','zone_wise')->where('application_status', 'denied')->latest()->paginate(config('default_pagination'));
        $zone = is_numeric($zone_id)?Zone::findOrFail($zone_id):null;
        return view('admin-views.delivery-man.denied', compact('delivery_men', 'zone'));
    }

}
