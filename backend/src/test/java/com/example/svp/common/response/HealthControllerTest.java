package com.example.svp.common.response;

import static org.junit.jupiter.api.Assertions.assertEquals;

import org.junit.jupiter.api.Test;

class HealthControllerTest {

    @Test
    void healthReportsUp() {
        assertEquals("UP", new HealthController().health().get("status"));
    }
}
