package middleware

import (
	"context"
	"net/http"
	"strings"

	"sigap-backend/utils"
)

type contextKey string

const UserContextKey contextKey = "user"

// Auth middleware untuk memvalidasi JWT token
func Auth(next http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		authHeader := r.Header.Get("Authorization")
		if authHeader == "" {
			utils.ErrorResponse(w, http.StatusUnauthorized, "Token tidak ditemukan")
			return
		}

		// Format: Bearer <token>
		parts := strings.SplitN(authHeader, " ", 2)
		if len(parts) != 2 || parts[0] != "Bearer" {
			utils.ErrorResponse(w, http.StatusUnauthorized, "Format token tidak valid")
			return
		}

		claims, err := utils.ValidateToken(parts[1])
		if err != nil {
			utils.ErrorResponse(w, http.StatusUnauthorized, "Token expired atau tidak valid")
			return
		}

		// Simpan claims ke context
		ctx := context.WithValue(r.Context(), UserContextKey, claims)
		next.ServeHTTP(w, r.WithContext(ctx))
	}
}

// AdminOnly middleware — hanya admin yang bisa akses
func AdminOnly(next http.HandlerFunc) http.HandlerFunc {
	return Auth(func(w http.ResponseWriter, r *http.Request) {
		claims := r.Context().Value(UserContextKey).(*utils.Claims)
		if claims.Role != "admin" {
			utils.ErrorResponse(w, http.StatusForbidden, "Akses ditolak: hanya admin")
			return
		}
		next.ServeHTTP(w, r)
	})
}

// StaffOnly middleware — admin atau psikolog
func StaffOnly(next http.HandlerFunc) http.HandlerFunc {
	return Auth(func(w http.ResponseWriter, r *http.Request) {
		claims := r.Context().Value(UserContextKey).(*utils.Claims)
		if claims.Role != "admin" && claims.Role != "psikolog" {
			utils.ErrorResponse(w, http.StatusForbidden, "Akses ditolak: hanya staff")
			return
		}
		next.ServeHTTP(w, r)
	})
}

// GetUserClaims helper untuk mengambil claims dari context
func GetUserClaims(r *http.Request) *utils.Claims {
	claims, ok := r.Context().Value(UserContextKey).(*utils.Claims)
	if !ok {
		return nil
	}
	return claims
}
