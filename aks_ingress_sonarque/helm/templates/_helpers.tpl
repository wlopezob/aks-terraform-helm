{{/*
Selector labels
*/}}
{{ define "k8s.labels" }}
app: {{ .Release.Name }}
tier: {{ $.Values.env }}
{{- if  $.Values.deployment.labels }}
{{- range $key, $map := $.Values.deployment.labels }}
{{ $key }}: {{ $map }}
{{- end }}
{{- end }}
{{- end }}