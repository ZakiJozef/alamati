<?php

namespace App\Notifications;

use App\Models\Demand;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Notification;

class NewDemandNotification extends Notification
{
    use Queueable;

    protected $demand;

    /**
     * Create a new notification instance.
     */
    public function __construct(Demand $demand)
    {
        $this->demand = $demand;
    }

    /**
     * Get the notification's delivery channels.
     */
    public function via(object $notifiable): array
    {
        return ['database'];
    }

    /**
     * Get the array representation of the notification.
     */
    public function toArray(object $notifiable): array
    {
        return [
            'demand_id' => $this->demand->id,
            'title' => $this->demand->title,
            'description' => substr($this->demand->description, 0, 100),
            'service_category' => $this->demand->service_category,
            'service_category_id' => $this->demand->service_category_id,
            'wilaya_id' => $this->demand->wilaya_id,
            'wilaya_name' => $this->demand->wilaya_name,
            'user_id' => $this->demand->user_id,
            'created_at' => $this->demand->created_at->toISOString(),
        ];
    }
}
