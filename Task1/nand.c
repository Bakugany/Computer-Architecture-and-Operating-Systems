#include <errno.h>
#include <stdbool.h>
#include <stddef.h>
#include <stdlib.h>

struct nand {
    struct list *outputs; // List of outputs of gate.
    unsigned number_of_inputs;
    struct Element *inputs; // Array of pointers of gate inputs.
    bool visited; // Checks if gate was already calculated in evaluate.
    bool value; // Keeps the value of gate.
    bool value_is_still_being_calculated; // Helps to check if we have cycle in our circuit.
    ssize_t length_of_critical_path;
};
typedef struct nand nand_t;

struct list { // List to keep entries to which our gate is connected.
    nand_t *gate; // Which gate our gate is connected to.
    unsigned which_entry;  // To which entry.
    struct list *next; // Pointer to the next element in list.
};

enum ElementType {
    ET_GATE, ET_SIGNAL, ET_NULL
}; // To every input of gate we can connect pointer to signal (bool*) or pointer to gate (nand_t*) or nothing (NULL).
struct Element {
    enum ElementType type;
    union {
        bool const *signal;
        nand_t *gate;
        void *universal;
    };
};

// Deletes from the list node with given gate g and given entry k.
static void delete_from_list(struct list **head, nand_t *g, unsigned k) {
    while ((*head)->gate != g || (*head)->which_entry != k) {
        head = &(*head)->next;
    }

    struct list *help = *head;
    *head = (*head)->next;
    free(help);
}

// Adds to the list node with given gate g and given entry k.
static bool add_to_the_beginning_of_the_list(struct list **head, nand_t *g, unsigned k) {
    struct list *new = malloc(sizeof(struct list)); // Allocate memory for new node.

    if (new == NULL) {  // Checks if the allocation was successful, if not returns false.
        return false;
    }

    new->next = *head;
    new->which_entry = k;
    new->gate = g;
    *head = new;

    return true;
}

// Cleans the whole list of outputs when we delete the gate.
static void delete_the_whole_list(struct list **head) {
    if (*head == NULL) {
        return;
    }

    struct list *help = *head;
    struct list *clean = *head;
    while (help->next != NULL) {
        help = help->next;
        free(clean);
        clean = help;
    }

    free(clean);
}

static bool DFS(nand_t *g) {
    if (g == NULL) {
        return false;
    }

    if (g->visited == true && g->value_is_still_being_calculated == true) {
        return false;
    }

    if (g->visited == true) {
        return true;
    }

    g->visited = true;

    bool result = true;
    bool there_is_false_connected_to_our_gate = false;
    ssize_t critical_path_of_subgates = 0;

    for (unsigned i = 0; i < g->number_of_inputs; i++) {
        if (g->inputs[i].universal == NULL) {
            return false;
        }

        if (g->inputs[i].type == ET_SIGNAL) {
            if (*(g->inputs[i].signal) == 0) {
                there_is_false_connected_to_our_gate = true;
            }
        }

        if (g->inputs[i].type == ET_GATE) {
            bool help = DFS(g->inputs[i].gate);

            if (!help) {
                result = false;
            }

            if (!g->inputs[i].gate->value) {
                there_is_false_connected_to_our_gate = true;
            }

            if (g->inputs[i].gate->length_of_critical_path > critical_path_of_subgates) {
                critical_path_of_subgates = g->inputs[i].gate->length_of_critical_path;
            }
        }
    }

    g->value = there_is_false_connected_to_our_gate;
    g->value_is_still_being_calculated = false;

    if (g->length_of_critical_path > 0) {
        g->length_of_critical_path = 1 + critical_path_of_subgates;
    }

    return result;
}

// When we finish evaluate we mark every gate as unvisited and that it's value is not calculated.
static void DFS_clean(nand_t *g) {
    g->visited = false;
    g->value_is_still_being_calculated = true;

    if (g->number_of_inputs == 0) {
        g->length_of_critical_path = 0;
    } else {
        g->length_of_critical_path = 1;
    }

    for (unsigned i = 0; i < g->number_of_inputs; i++) {
        if (g->inputs[i].type == ET_GATE && g->inputs[i].gate->visited) {
            DFS_clean(g->inputs[i].gate);
        }
    }
}

nand_t *nand_new(unsigned n) {
    nand_t *result = (nand_t *) malloc(sizeof(nand_t));

    if (result == NULL) { // If allocation was unsuccessful we return NULL.
        errno = ENOMEM;
        return NULL;
    }

    if(n != 0) {
        result->inputs = malloc(n * sizeof(struct Element));
    }

    if(n == 0){
        result->inputs = NULL;
    }

    if (result->inputs ==
        NULL && n != 0) { // If allocation of array of inputs was unsuccessful we remove whole gate and return NULL.
        free(result);
        errno = ENOMEM;
        return NULL;
    }

    for (unsigned i = 0; i < n; i++) {
        result->inputs[i].universal = NULL;
        result->inputs[i].type = ET_NULL;
    }

    result->outputs = NULL;
    result->value_is_still_being_calculated = true;
    result->number_of_inputs = n;
    result->visited = false;

    if (n == 0) {
        result->length_of_critical_path = 0;
    } else {
        result->length_of_critical_path = 1;
    }

    return result;
}

void nand_delete(nand_t *g) {
    if (g == NULL) {
        return;
    }

    for (unsigned i = 0; i < g->number_of_inputs; i++) { // Deletes gate g from outputs of other gates.
        if (g->inputs[i].type == ET_GATE) {
            nand_t *help = g->inputs[i].gate;
            delete_from_list(&(help->outputs), g, i);
        }
    }

    if (g->outputs != NULL) { // Deletes gate g from inputs of other gates.
        struct list *help = g->outputs;
        while (help != NULL) {
            nand_t *clean = help->gate;
            clean->inputs[help->which_entry].universal = NULL;
            clean->inputs[help->which_entry].type = ET_NULL;
            help = help->next;
        }
    }

    delete_the_whole_list(&(g->outputs));

    if (g->number_of_inputs > 0) {
        free(g->inputs);
    }

    free(g);
}

int nand_connect_nand(nand_t *g_out, nand_t *g_in, unsigned k) {
    if (g_in == NULL || k >= g_in->number_of_inputs || g_out == NULL) {
        errno = EINVAL;
        return -1;
    }

    bool result = add_to_the_beginning_of_the_list(&(g_out->outputs), g_in, k);
    if (!result) {
        errno = ENOMEM;
        return -1;
    }

    if (g_in->inputs[k].type == ET_GATE) {
        nand_t *help = g_in->inputs[k].gate;
        delete_from_list(&(help->outputs), g_in, k);
    }

    g_in->inputs[k].type = ET_GATE;
    g_in->inputs[k].gate = g_out;

    return 0;
}

int nand_connect_signal(bool const *s, nand_t *g, unsigned k) {
    if (g == NULL || k >= g->number_of_inputs || s == NULL) {
        errno = EINVAL;
        return -1;
    }

    if (g->inputs[k].type == ET_GATE) {
        nand_t *help = (nand_t *) g->inputs[k].gate;
        delete_from_list(&(help->outputs), g, k);
    }

    g->inputs[k].type = ET_SIGNAL;
    g->inputs[k].signal = s;
    return 0;
}

ssize_t nand_evaluate(nand_t **g, bool *s, size_t m) {
    if (m == 0 || g == NULL || s == NULL) {
        errno = EINVAL;
        return -1;
    }

    ssize_t length_of_critical = 0;

    for (size_t i = 0; i < m; i++) {
        if (g[i] == NULL) {
            for (size_t j = 0; j < i; j++) {
                DFS_clean(g[j]);
            }
            errno = EINVAL;
            return -1;
        }

        if (!DFS(g[i])) {
            for (size_t j = 0; j <= i; j++) {
                DFS_clean(g[j]);
            }
            errno = ECANCELED;
            return -1;
        }

        s[i] = g[i]->value;

        if (length_of_critical < g[i]->length_of_critical_path) {
            length_of_critical = g[i]->length_of_critical_path;
        }
    }

    for (size_t i = 0; i < m; i++) {
        DFS_clean(g[i]);
    }

    return length_of_critical;
}

ssize_t nand_fan_out(nand_t const *g) {
    if (g == NULL) {
        errno = EINVAL;
        return -1;
    }

    if (g->outputs == NULL) {
        return 0;
    }

    struct list *iterator = g->outputs;
    ssize_t result = 1;
    while (iterator->next != NULL) {
        iterator = iterator->next;
        result++;
    }

    return result;
}

void *nand_input(nand_t const *g, unsigned k) {
    if (g == NULL || k >= g->number_of_inputs) {
        errno = EINVAL;
        return NULL;
    }

    if (g->inputs[k].universal == NULL) {
        errno = 0;
        return NULL;
    }

    return g->inputs[k].universal;
}

nand_t *nand_output(nand_t const *g, ssize_t k) {
    if (g == NULL && k < 0) {
        errno = EINVAL;
        return NULL;
    }

    if (k >= nand_fan_out(g)) {
        errno = EINVAL;
        return NULL;
    }

    struct list *iterator = g->outputs;
    for (ssize_t i = 0; i < k; i++) {
        iterator = iterator->next;
    }

    return iterator->gate;
}
