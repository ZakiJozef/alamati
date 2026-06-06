<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;

/**
 * Middleware to handle X-Authorization header for shared hosting environments
 * that strip the standard Authorization header.
 */
class HandleXAuthorizationHeader
{
    /**
     * Handle an incoming request.
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  \Closure  $next
     * @return mixed
     */
    public function handle(Request $request, Closure $next)
    {
        // If no Authorization header but X-Authorization exists, copy it
        if (!$request->headers->has('Authorization') && $request->headers->has('X-Authorization')) {
            $request->headers->set('Authorization', $request->headers->get('X-Authorization'));
        }

        return $next($request);
    }
}
