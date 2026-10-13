package com.voaaguia.security;
import com.voaaguia.domain.User;
import com.voaaguia.repository.UserRepository;
import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import java.util.Locale;

@Component @ConditionalOnProperty(name="app.seed-enabled",havingValue="true")
public class DevelopmentSeed implements CommandLineRunner {
    private final UserRepository users; private final PasswordEncoder passwords; private final String password;
    public DevelopmentSeed(UserRepository users,PasswordEncoder passwords,@Value("${app.seed-password}") String password) { this.users=users; this.passwords=passwords; this.password=password; }
    @Override public void run(String... args) {
        if(password.length()<12) throw new IllegalArgumentException("SEED_PASSWORD precisa de pelo menos 12 caracteres");
        for(String role:new String[]{"OPERADOR","GESTOR","LIDER"}) {
            String email=role.toLowerCase(Locale.ROOT)+"@voaaguia.local";
            if(users.findByEmail(email).isPresent()) continue;
            var u=new User(); u.email=email; u.name=role; u.role=role; u.department="Inovação"; u.passwordHash=passwords.encode(password); users.save(u);
        }
    }
}
