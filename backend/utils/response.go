package utils

import (
	"encoding/json"
	"net/http"
)

// JSONResponse helper untuk mengirim response JSON
func JSONResponse(w http.ResponseWriter, status int, data interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	json.NewEncoder(w).Encode(data)
}

// ErrorResponse helper untuk mengirim error response
func ErrorResponse(w http.ResponseWriter, status int, message string) {
	JSONResponse(w, status, map[string]string{"error": message})
}

// SuccessResponse helper untuk mengirim success response
func SuccessResponse(w http.ResponseWriter, message string, data interface{}) {
	resp := map[string]interface{}{
		"message": message,
	}
	if data != nil {
		resp["data"] = data
	}
	JSONResponse(w, http.StatusOK, resp)
}
