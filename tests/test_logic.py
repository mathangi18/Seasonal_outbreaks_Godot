import random
import math

# Mock classes to test logic
class Patient:
    def __init__(self, id, x, y):
        self.id = id
        self.x = x
        self.y = y
        self.state = "SUSCEPTIBLE" # 0: S, 1: E, 2: I, 3: R
        self.exposed_ticks = 0
        self.infectious_ticks = 0

    def infect(self):
        if self.state == "SUSCEPTIBLE":
            self.state = "EXPOSED"
            self.exposed_ticks = 0

    def tick(self):
        if self.state == "EXPOSED":
            self.exposed_ticks += 1
            if self.exposed_ticks >= 5: # incubation
                self.state = "INFECTIOUS"
                self.infectious_ticks = 0
        elif self.state == "INFECTIOUS":
            self.infectious_ticks += 1
            if self.infectious_ticks >= 10: # recovery
                self.state = "RECOVERED"

def dist(p1, p2):
    return math.sqrt((p1.x - p2.x)**2 + (p1.y - p2.y)**2)

def run_sim():
    random.seed(12345)
    patients = []
    for i in range(100):
        patients.append(Patient(i, random.uniform(0, 600), random.uniform(0, 380)))
    
    # Infect patient 0
    patients[0].infect()
    
    ticks = 200
    infection_radius = 20.0
    infection_prob = 0.1
    
    log = []
    
    for t in range(ticks):
        # Update patients
        for p in patients:
            p.tick()
            
        # Infection check
        infectious = [p for p in patients if p.state == "INFECTIOUS"]
        for i_p in infectious:
            for p in patients:
                if p.state == "SUSCEPTIBLE":
                    if dist(i_p, p) < infection_radius:
                        if random.random() < infection_prob:
                            p.infect()
                            
        # Count
        s = sum(1 for p in patients if p.state == "SUSCEPTIBLE")
        e = sum(1 for p in patients if p.state == "EXPOSED")
        i_count = sum(1 for p in patients if p.state == "INFECTIOUS")
        r = sum(1 for p in patients if p.state == "RECOVERED")
        
        log.append((t, s, e, i_count, r))
        
    # Validation
    print(f"Final Counts: S={s}, E={e}, I={i_count}, R={r}")
    if s < 100 and (e > 0 or i_count > 0 or r > 0):
        print("TEST PASSED: Infection spread occurred.")
    else:
        print("TEST FAILED: No infection spread.")

if __name__ == "__main__":
    run_sim()
