package com.voaaguia.api;

import java.util.Map;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirements;
import org.bson.Document;
import org.springframework.data.mongodb.core.MongoTemplate;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class HealthController {
    private final MongoTemplate mongo;

    public HealthController(MongoTemplate mongo) {
        this.mongo = mongo;
    }

    @GetMapping("/healthz")
    @SecurityRequirements
    @Operation(summary = "Verificar saúde da API e conexão com MongoDB")
    public Map<String, String> health() {
        // Se o MongoDB estiver indisponivel, a verificacao retorna erro (HTTP 5xx).
        mongo.getDb().runCommand(new Document("ping", 1));
        return Map.of("status", "UP", "application", "voaaguia");
    }
}
